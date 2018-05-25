c = loadcase('case30');
LoadBuses = find(c.bus(:,3)>0);
Loads = c.bus(LoadBuses,3);
KaggleLoads = get_load('data/Load_history.csv',2008,1);
K = KaggleLoads;
KaggleLoads = [];

for day = 1:31
    Day = K(:,(day-1)*24+1:day*24);
    DailyMax = max(Day')';
    Day = diag(1./DailyMax)*Day;
    KaggleLoads = [KaggleLoads Day];
end
KaggleLoads = diag(Loads)*KaggleLoads;
save data/KaggleLoads.mat KaggleLoads