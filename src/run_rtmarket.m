%%
% run real time market

disp('generating LMP for every 5 minutes...')
mdata.S = [];
mdata.M = [];
mdata.Prices = [];
mdata.index = [];
for h = 1:24
    fprintf('hour %d:\n',h)
    for i = 1:12
        market = rtmarket(db, h);
        mdata.S = [mdata.S, market.s];
        mdata.M = [mdata.M, market.muh-market.mul];
        mdata.Prices = [mdata.Prices, market.price];
        if market.success && market.cong
            mdata.index = [mdata.index, (h-1)*12+i];
        end
    end
end
mdata.PricesClean = mdata.Prices(:,mdata.index);
mdata.SClean = mdata.S(:,mdata.index);
mdata.MClean = mdata.M(:,mdata.index);

save data/mdata.mat mdata