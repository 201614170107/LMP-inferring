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
run_rt = 0;
if run_rt ==1
    run_rtmarket
else
    load data/mdata.mat
end

%% 
% online admm
load data/Market_with_changes.mat
Bo = makeBmatrix(mpc);
Bo = Bo / max(max(Bo));
L0 = get_lap(Bo,REF);
online_results = online_admm2(mdata.PricesClean, [0.1,0.1,0.1], Bo);
a = online_results.B3(22,25,:);
figure,
plot(a(:));
B_final = online_results.B3(:,:,end);
plot_mat(B_final,'parula','B0');
L_final = get_lap(B_final, REF);
plot_mat(L_final,'jet','L')

online_results2 = online_admm(mdata.PricesClean, [0.1,0.1,0.1],Bo);
b = online_results2.B3(22,25,:);
figure,
plot(b(:));
B_final2 = online_results2.B3(:,:,end);
plot_mat(B_final2,'parula','B0');
L_final2 = get_lap(B_final2, REF);

figure,
hold on,
title('ROC')
xlabel('FPR')
ylabel('TPR')
axis([0,0.15,0,1])
[TPR1,FPR1] = evaluation(L0,L_final);
plot(FPR1,TPR1,'r^')

[TPR2,FPR2] = evaluation(L0,L_final2);
plot(FPR2,TPR2,'b*')
hold off

%%
% inferring the Laplacian matrix from LMP
B0 = makeBmatrix(mpc);
plot_mat(B0,'parula','B0');
L0 = get_lap(B0,REF);
plot_mat(L0,'jet','L0');

k0 = 0.1;
k = [k0,k0];
B1 = B_Kekatos(mdata.PricesClean, k);
plot_mat(B1,'parula','B1');
L1 = get_lap(B1,REF);
plot_mat(L1,'jet','L1');

k = [k0,k0,k0/(db.N-2)];
B2 = B_estimate(mdata.PricesClean, k);
plot_mat(B2,'parula','B2');
L2 = get_lap(B2,REF);
plot_mat(L2,'jet','L2');

% plot the ROC curve
figure,
hold on,
title('ROC')
xlabel('FPR')
ylabel('TPR')
axis([0,0.15,0,1])
[TPR1,FPR1] = evaluation(L0,L1);
plot(FPR1,TPR1,'b*')

[TPR2,FPR2] = evaluation(L0,L2);
plot(FPR2,TPR2,'r^')
hold off

%%
% constructing PTDF matrix from the inferred Laplacian matrix
[A2,x2,f2,t2] = L2A(L2);
X2 = diag(1./x2);
A2(:,REF) = [];
B2_2 = L2([1:REF-1,REF+1:end],[1:REF-1,REF+1:end]);
T2 = [zeros(size(A2,1),1),X2*A2*B2_2^(-1)];
plot_mat(T2,'jet',0)
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