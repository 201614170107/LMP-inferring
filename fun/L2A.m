function [A,x,f,t] = L2A(L)
    nb = size(L,1);
    f = [];
    t = [];
    x = [];
    for i = 1:nb-1
        for j = i+1:nb
            if abs(L(i,j)) > 1e-3
                f = [f;i];
                t = [t;j];
                x = [x;1/abs(L(i,j))];
            end
        end
    end
    nl = length(f);
    Cf = sparse(1:nl, f, ones(nl, 1), nl, nb);
    Ct = sparse(1:nl, t, ones(nl, 1), nl, nb);
    A = Cf-Ct;

end