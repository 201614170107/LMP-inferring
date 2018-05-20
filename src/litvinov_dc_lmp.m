function [LMP,LMP_E,LMP_L,LMP_C, U, success,results,LF] = Litvinov_dc_LMP(mpc)
% function [LMP,LMP_E,LMP_L,LMP_C, success] = Litvinov_dc_LMP(mpc)
pfopt = mpoption('model','ac','verbose',0);
results = runpf(mpc,pfopt);
r = mpc.branch(:,3);
p_branch = (results.branch(:,14) - results.branch(:,16))/2;
p_branch = p_branch / mpc.baseMVA;
T = makePTDF(mpc);
LF = 2*(r.*p_branch)'*T;
LF = LF';
nb = size(mpc.bus,1);
nl = length(r);
Pg = zeros(nb,1);
gen_bus = results.gen(:,1);
Pg(gen_bus,1) = results.gen(:,2);
Pd = mpc.bus(:,3);
l = sum(Pg-Pd);
l0 = l - LF'*(Pg-Pd);

from = mpc.branch(:,1);
to = mpc.branch(:,2);
Ei = zeros(nb,1);
for i = 1:nb
    Mi = find(from == i | to == i);
    Ei(i) = 0.5 * p_branch(Mi)'.^2 * r(Mi);
end
D = Ei/sum(Ei);
mpopt = mpoption('model','dc','verbose',0);
om = opf_model(mpc);

om = Litvinov_dc_opf_setup(mpc, mpopt,l0,D,T,LF);
om = build_cost_params(om);
[results, success, raw] = dcopf_solver(om, mpopt);
results = int2ext(results);
lambda = results.mu.lin.u-results.mu.lin.l;

LMP_E = - repmat(lambda(2),nb,1)/mpc.baseMVA;
LMP_L = lambda(2)*LF/mpc.baseMVA;
LMP_C = - (T'-(T*D*ones(1,nb))')*lambda(3:nl+2)/mpc.baseMVA; 
LMP = LMP_E + LMP_L + LMP_C;
U = lambda(3:nl+2);
end