function db = create_db(mpc,loads,c,pmin,pmax)
    LoadBuses = find(mpc.bus(:,3)>0);
    db.loads = loads;
    db.N = length(mpc.bus(:,1));
    db.loads = zeros(db.N,size(loads,2));
    db.loads(LoadBuses,:) = loads;
    db.x = 1./mpc.branch(:,4);
    db.L = length(db.x);
    db.A = makeAmatrix(mpc);
    REF = find(mpc.bus(:,2)==3);
    db.Ar = db.A;
    db.Ar(:,REF) = [];
    db.Br = makeBmatrix(mpc);
    db.Bri = db.Br^(-1);
    db.flowlimit = mpc.branch(:,6); 
    db.pmin = pmin;
    db.pmax = pmax;
    db.c = c;
end