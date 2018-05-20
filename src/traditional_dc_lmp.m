function [LMP, LMP_E, LMP_C, U, success, results] = traditional_dc_lmp(mpc)
% function [LMP, LMP_E, LMP_C, success] = Traditional_dc_LMP(mpc)
mpopt = mpoption('model','dc','verbose',0);
om = opf_model(mpc);
om = opf_setup(mpc, mpopt);
om = build_cost_params(om);
[results, success, raw] = dcopf_solver(om, mpopt);
try 
    results = int2ext(results);
catch error
    %
end
lambda = results.mu.lin.u-results.mu.lin.l;

T = makePTDF(mpc);
nb = size(mpc.bus, 1);    %% number of buses
nl = size(mpc.branch, 1); %% number of branches
LMP = lambda(1:nb)/mpc.baseMVA;
LMP_C = T'* lambda(nb+1:nb+nl)/mpc.baseMVA;
LMP_E = LMP + LMP_C;

U = lambda(nb+1:nb+nl);
end