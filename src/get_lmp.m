function [PI,PI_E,PI_C,PI_L,feasible,congestion,congest_idx] = get_lmp(mpc,load_data,e,method)
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

feasible = 0;
congestion = 0;
congest_idx = [];
PI = [];
PI_E = [];
PI_L = [];
PI_C = [];
for i = 1:size(load_data,2)
    mpc.bus(:,3) = load_data(:,i);
    switch lower(method)
        case 'traditional'
            [LMP,LMP_E,LMP_C, U, success] = traditional_dc_lmp(mpc);
        case 'litvinov'
            [LMP,LMP_E,LMP_L,LMP_C, U, success] = litvinov_dc_lmp(mpc);
    end
    if success
        feasible = feasible + 1;
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
            line_idx = find(abs(U)>e);
            congest_idx= [congest_idx;line_idx];
        end
    end
end
congest_idx = unique(congest_idx);

end