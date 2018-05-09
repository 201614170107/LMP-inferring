function B = B_Kekatos(PI_E,PI_C,REF,k,avg_degree,e)
% function B = B_Kekatos(PI_E,PI_C,REF,k,avg_degree,e)
if nargin < 6
    e = 1e-3;
    if nargin < 5
        avg_degree = 0;
    end
end

PI = PI_E+PI_C;
kappa1 = k(1);
kappa2 = k(2);
nb = size(PI,1);
PI = PI - repmat(PI(REF,:),nb,1);
PI = PI([1:REF-1,REF+1:nb],:);
IDX_congestion = sum(abs(PI_C),1)>0 ;
PI = PI(:,IDX_congestion);

B_solve = sdpvar(nb-1,nb-1);
I = eye(nb-1);
F = [B_solve >= 0, B_solve(:) <= I(:)];
P = I - ones(nb-1,nb-1);
% optimize(F,norm(B_solve*PI,1)+kappa1*trace(P*B_solve)-kappa2*logdet(B_solve),sdpsettings('solver','sdpt3'));
E = ones(1,nb-1);
optimize(F,norm(B_solve*PI,1)+kappa1*trace(P*B_solve)-kappa2*logdet(B_solve),sdpsettings('solver','sdpt3'));

BS = value(B_solve);

if avg_degree>0
    degree = mean(diag(BS));
    B = BS * avg_degree/degree; 
else 
    B = BS;
end
B(abs(B)<e) = 0;
end

