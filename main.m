%%
% preprocess
clear,
clc,
addpath('src')
addpath('case')
addpath('fun')
% delete 'data/train_data.csv'
% delete 'data/test_data.csv'
case_str = 'case30_modified';
mpc = ext2int(loadcase(case_str));
divergence = 0.1;
divide = 7000*ones(30,1);
year = 2007;
month = 12;
day = [23];

REF = find(mpc.bus(:,2) == 3);
nb = size(mpc.bus, 1);    %% number of buses
nl = size(mpc.branch, 1);    %% number of lines

if exist('data/train_data.csv','file') == 2
    gen_data = csvread('data/train_data.csv');
else
    gen_data = gen_load('data/Load_history.csv','data/train_data.csv', mpc, divergence, year, month, day, divide);
end

day = [24];
if exist('data/test_data.csv','file') == 2
    gen_data = csvread('data/test_data.csv');
else
    gen_data = gen_load('data/Load_history.csv','data/test_data.csv', mpc, divergence, year, month, day, divide);
end

%%
% inferring the Laplacian matrix from LMP
[PI,PI_E,PI_C,PI_L,PO,feasible,feasible_time,congestion,congest_time,congest_idx] = get_lmp(mpc,gen_data);

B0 = makeBmatrix(mpc);
plot_mat(B0,'parula','B0');
L0 = get_lap(B0,REF);
plot_mat(L0,'jet','L0');

k = [0.01,0.01];
B1 = B_Kekatos(PI_E,PI_C,REF, k);
plot_mat(B1,'parula','B1');
L1 = get_lap(B1,REF);
plot_mat(L1,'jet','L1');

k = [0.01,0.01,0.01/(nb-1)];
B2 = B_estimate(PI_E,PI_C,REF, k);
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
[TPR1,FPR1] = evaluation(B0,B1);
plot(FPR1,TPR1,'b*')

[TPR2,FPR2] = evaluation(B0,B2);
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

load_idx = find(mpc.bus(:,3)>0);
for i = 1:5
    j = find(limit == min(limit));
    m = f2(j);
    n = t2(j);
    L2(m,m) = L2(m,m) + L2(m,n);
    L2(n,n) = L2(n,n) + L2(m,n);
    L2(m,n) = 0;
    L2(n,m) = 0;
    [A2,x2,f2,t2] = L2A(L2);
    X2 = diag(1./x2);
    A2(:,REF) = [];
    B2_2 = L2([1:REF-1,REF+1:end],[1:REF-1,REF+1:end]);
    T2 = [zeros(size(A2,1),1),X2*A2*B2_2^(-1)];
    % plot_mat(T2,'jet',0)
    Pf2 = T2 * PO;
    limit = max(abs(Pf2),[],2);
    mpc2 = create_mpc(mpc, f2, t2, x2, limit);
    [PI2,~,~,~,~,~,feasible_time2]  = get_lmp(mpc2,gen_data);
    figure,
    plot(1:size(PI2,2),PI2)
end

success_time = intersect(feasible_time,feasible_time2);
for i = 1:nb
    figure,
    hold on,
    title(sprintf('LMP of bus %d',i))
    plot(1:length(success_time),PI(i,success_time),'b-')
    plot(1:length(success_time),PI2(i,success_time),'r-')
    hold off
    print(sprintf('fig/bus%d.eps',i),'-depsc')
end