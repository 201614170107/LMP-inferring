function [PI,PI_E,PI_C,PI_L,PO,feasible,feasible_time,congestion,congest_time,congest_idx] = get_lmp(mpc,load_data,e,method)
% function [PI,PI_E,PI_C,PI_L,feasible,congestion,congest_idx] = get_lmp(mpc,load_data,e,method)
% supported method:
% 'traditional' - traditional dc LMP;
% 'litvinov' - litvinov dc LMP.
% e is the threshold, default 1e-3.
%% default arguments
if nargin < 4
    method = 'traditional'; % default method is traditional dc LMP.
    if nargin < 3
        e = 1e-3;
    end
end
%%
nb = length(mpc.bus(:,1));
feasible = 0;
congestion = 0;
feasible_time = [];
congest_idx = [];
congest_time = [];
PI = [];
PI_E = [];
PI_L = [];
PI_C = [];
PO = [];
for i = 1:size(load_data,2)
    mpc.bus(:,3) = load_data(:,i);
    switch lower(method)
        case 'traditional'
            [LMP,LMP_E,LMP_C, U, success, results] = traditional_dc_lmp(mpc);
        case 'litvinov'
            [LMP,LMP_E,LMP_L,LMP_C, U, success] = litvinov_dc_lmp(mpc);
    end
    if success
        if max(LMP)> 200
            max(LMP)
            mpopt = mpoption('model','dc','verbose',1);
            results.success = 1;
            results.et = 1;
            printpf(results, 1, mpopt);
        end
        feasible = feasible + 1;
        feasible_time = [feasible_time, i];
        P_out = results.bus(:,3);
        P_out(results.gen(:,1)) = P_out(results.gen(:,1)) - results.gen(:,2);
        PO = [PO,P_out];
        LMP_C(abs(LMP_C)<1e-3) = 0;
        PI = [PI,LMP];
        PI_E = [PI_E,LMP_E];
        PI_C = [PI_C,LMP_C];
        try
            PI_L = [PI_L,LMP_L];
        catch error
            % pass
        end
        if norm0(LMP_C) >0
            congestion = congestion +1;
            congest_time = [congest_time,i];
            line_idx = find(abs(U)>e);
            congest_idx= [congest_idx;line_idx];
        end
    else
        PI = [PI, zeros(nb,1)];
    end
end
congest_idx = unique(congest_idx);

end