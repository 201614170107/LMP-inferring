%%
% preprocess
clear,
clc,
addpath('src')
addpath('case')
addpath('fun')
mpc = loadcase('case30');
REF = find(mpc.bus(:,2)==3);
% delete 'data/KaggleLoads.mat'
try 
    load data/KaggleLoads.mat
catch error
    disp('Load .mat file does not exist. Generating...')
    data_preprocess,
end
block_offer,
db = create_db(mpc,KaggleLoads./0.625,c,pmin,pmax);
clear c pmin pmax,

%%
% real time market or load the market data.
run_rt = 1;
if run_rt ==1
    run_rtmarket
else
    load data/mdata.mat
end

%% 
% online admm
% load data/Market_with_changes.mat
Bo = makeBmatrix(mpc);
L0 = get_lap(Bo,REF);
Bo = Bo / max(max(Bo));
online_results = online_admm2(mdata.Prices, 0.005*[1,1]);
online_results2 = online_admm(mdata.Prices, 0.005*[1,1]);
% B_final = online_results.B3(:,:,end);
% plot_mat(B_final,'jet','B1');
% B_final = online_results2.B3(:,:,end);
% plot_mat(B_final,'jet','B2');

a = online_results.B3(22,25,:);
b = online_results2.B3(22,25,:);
AUC = zeros(1,length(a));
AUC2 = zeros(1,length(a));
parfor i = 1:length(a)
    B_final = online_results.B3(:,:,i);
    L_final = get_lap(B_final,REF);

    B_final2 = online_results2.B3(:,:,i);
    L_final2 = get_lap(B_final2,REF);
    AUC(i) = evaluation(L0,L_final);
    AUC2(i) = evaluation(L0,L_final2);
end
figure, hold on,
plot(AUC,'r-'),plot(AUC2,'b-')
hold off
%%
% constructing PTDF matrix from the inferred Laplacian matrix
for time = 1000:size(mdata.Prices,2)
    fprintf('time=%d\n',time)
    L_infered = get_lap(online_results.B3(:,:,time),REF);
    avg_degree = mean(diag(L_infered));
    L_infered = L_infered/avg_degree * mean(diag(L0));
    db_infered = L2A(L_infered, REF);
    Pf = diag(db_infered.x)*db_infered.Ar*db_infered.Bri* ...
        (mdata.gen(2:end,1:time)-mdata.loads(2:end,1:time) );
    db_infered.flowlimit = max(abs(Pf),[],2);
    
    train_error_min = 100;
    while (1)
        db_infered = line_reduce(db_infered, mdata ,REF, time);
        fprintf('nl=%d\n',db_infered.L)
        if db_infered.L <= 100
            db_infered.pmin = db.pmin; db_infered.pmax = db.pmax;
            mdata2 = get_lmp(db_infered, mdata, (time-287):time);
            train_error = rmse(mdata2.Prices,mdata.Prices(:,(time-287):time));
            fprintf('training rmse=%g\n',train_error)
            if train_error<train_error_min
                db_reduced = db_infered;
                train_error_min = train_error;
            end
            if db_infered.L <= 41
                fprintf('min training rmse=%g\n',train_error_min)
                break
            end
        end
    end
end


[A2,x2,f2,t2] = L2A(L_infered, REF);
X2 = diag(1./x2);
A2(:,REF) = [];
B2_2 = L_infered([1:REF-1,REF+1:end],[1:REF-1,REF+1:end]);
T2 = [zeros(size(A2,1),1),X2*A2*B2_2^(-1)];
plot_mat(T2,'jet','T',0)
Pf2 = T2 * PO;
limit = max(abs(Pf2),[],2);

%%
% create equivalent mpc
mpc2 = create_mpc(mpc, f2, t2, x2, limit);
[PI2,~,~,~,~,~,feasible_time2]  = get_lmp(mpc2,gen_data);
figure,
plot(1:size(PI2,2),PI2)

load_idx = find(mpc.bus(:,3)>0)';
for i = 1:21
    [L2, f2, t2, x2, T2] = line_reduce(limit, L2, f2, t2, REF);
    Pf2 = T2 * PO;
    limit = max(abs(Pf2),[],2);
    mpc2 = create_mpc(mpc, f2, t2, x2, limit);
    [PI2,~,~,~,~,~,feasible_time2]  = get_lmp(mpc2,gen_data);
    success_time = intersect(feasible_time,feasible_time2);
    loss1 = [];
    for j = load_idx
        loss1 = [loss1, rmse(PI(j,success_time),PI2(j,success_time))];
    end
    fprintf('Line Reduce %d, mean loss =%g, max loss =%g\n',i, mean(loss1), max(loss1))
end

%%
% print to files
for i = load_idx
    figure,
    hold on,
    title(sprintf('LMP of bus %d',i))
    plot(1:length(success_time),PI(i,success_time),'b-')
    plot(1:length(success_time),PI2(i,success_time),'r-')
    hold off
    print(sprintf('fig/train_bus%d.eps',i),'-depsc')
    close
end

%%
% testing
[PI,PI_E,PI_C,PI_L,PO,feasible,feasible_time,congestion,congest_time,congest_idx] = get_lmp(mpc,test_data);
[PI2,~,~,~,~,~,feasible_time2]  = get_lmp(mpc2, test_data);
success_time = intersect(feasible_time,feasible_time2);
loss2 = [];
for j = load_idx
    loss2 = [loss2, rmse(PI(j,success_time),PI2(j,success_time))];
end
fprintf('Testing, mean loss =%g, max loss =%g\n', mean(loss2), max(loss2))
for i = load_idx
    figure,
    hold on,
    title(sprintf('LMP of bus %d',i))
    plot(1:length(success_time),PI(i,success_time),'b-')
    plot(1:length(success_time),PI2(i,success_time),'r-')
    hold off
    print(sprintf('fig/test_bus%d.eps',i),'-depsc')
    close
end
system('fig\eps2pdf.bat');