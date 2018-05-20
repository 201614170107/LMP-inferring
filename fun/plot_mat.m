function y = plot_mat(B,map,title_txt,norm,e,showtext)
% y = PLOT_LAP(B,map,norm,e,title_txt,showtext)
%% default arguments
if nargin < 6
    showtext = 0;
    if nargin < 5 
        e = 1e-3;
        if nargin < 4
            norm = 1;
            if nargin <3 
                title_txt = 'MATRIX';
            end
        end
    end
end
B(abs(B)<e) = 0;
figure,
colormap(map)
if norm > 0 
    L = B / max(max(B));
else
    L = B;
end
image(L,'CDataMapping','scaled'),
colorbar
if showtext
hold on;
    for i = 1:size(L,1)
      for j = 1:size(L,2)
          nu = L(i,j);
          val = num2str(round(nu,2));
          text(i,j,val)
      end
    end
    hold off;
end
title(title_txt)
y = 1;
end