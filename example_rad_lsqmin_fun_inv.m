function er = example_rad_lsqmin_fun(X,x,para)
c = para(1:2).*1e4; %For normalized distortion, comment this line
%c = para(1:2); %For normalized distortion, uncomment this line
sx = para(3);
t = para(4:5);
tc = para(6:7);
r = para(2+1+2+2 +1:end); %Radiaaliv��ristym�n kertoimet
r = r./(10.^(1:3:(numel(r)*3)))'; %Korjataan kertoimet %For normalized distortion, comment this line


X = distort(X,r,c,sx,t,tc);
H = makeH(x,X);

er = sum((wnorm(H*x)-X).^2)';

