function gen_data = gen_load(input, output, mpc, divergence, year, month, day, divide)
% function load_data = gen_load(input, output, mpc, divergence, year, month, day, divide)
[num,~, raw ] = xlsread(input);
num = num(num(:,2)==year & num(:,3)==month,:);
load_series = [];
for k = day
    day_load = num(num(:,4)==k,5:end);
    load_series = [load_series,day_load];
end


demand = mpc.bus(:,3);
original_demand = demand(demand~=0);
[~,I1] = sort(original_demand,'descend');
[~,I2] = sort(mean(load_series,2),'descend');
load_series(I1,:) = load_series(I2,:);

gen_data = [];
for i = 1:size(load_series,2)
    for j = 1:12
        % 12 points in an hour
        demand = mpc.bus(:,3);
        demand(demand~=0) = load_series(:,i).*(1 + divergence* randn(size(original_demand,1),1));
        demand = demand./divide;
        gen_data = [gen_data,demand];
    end
end

csvwrite(output,gen_data);

end