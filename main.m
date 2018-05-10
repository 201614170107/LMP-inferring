%%
% main
clear,
clc,
addpath('src')
addpath('case')

case_str = 'case30_modified';
mpc = ext2int(loadcase(case_str));
divergence = 0.1;
divide = 7000;
year = 2007;
month = 12;
day = 23;

REF = find(mpc.bus(:,2) == 3);
nb = size(mpc.bus, 1);    %% number of buses

if exist('data/gen_data.csv','file') == 2
    gen_data = csvread('data/gen_data.csv');
else
    gen_data = gen_load('data/Load_history.csv', mpc, divergence, year, month, day, divide);
end

[PI,PI_E,PI_C,PI_L,feasible,congestion,congest_idx] = get_lmp(mpc,gen_data);

k = [0.01,0.01];
B = B_Kekatos(PI_E,PI_C,REF, k);

plot_mat(B,'parula');
L = get_lap(B,REF);
plot_mat(L,'jet');

k = [0.01,0.01,0.01/(nb-1)];
B = B_estimate(PI_E,PI_C,REF, k);
plot_mat(B,'parula');
L = get_lap(B,REF);
plot_mat(L,'jet');
