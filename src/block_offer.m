%%
%block offer
c = zeros(30, 5);
c(1,:) = [26  36  44  50  0];
c(2,:) = [21  28  35  43  0];
c(13,:) = [18  42  47  0  0];
c(22,:) = [16  27  41  54  66];
c(23,:) = [34  40  0   0   0];
c(27,:) = [35  39  0   0   0];

%%
pmin = zeros(30,5);
pmax = zeros(30,5);
pmax(1,:) = [30	20	20	10	0];
pmax(2,:) = [20	20	20	20	0];
pmax(13,:) = [15 15	10	0	0];
pmax(22,:) = [10 10	10	10	10];
pmax(23,:) = [15 15	0	0	0];
pmax(27,:) = [30 25	0	0	0];

