function y = plot_mat(B,map,e,title_txt,showtext)
% y = PLOT_LAP(B,map,e,title_txt,showtext)
%% default arguments
if nargin < 5
    showtext = 0;
    if nargin < 4 
        title_txt = 'MATRIX';
        if nargin < 3
            e = 1e-3;
        end
    end
end
B(abs(B)<e) = 0;
figure,
colormap(map)
L = B / max(max(B));
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