function [L2, f2, t2, x2, T2] = line_reduce(limit, L2, f2, t2, REF)
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
end