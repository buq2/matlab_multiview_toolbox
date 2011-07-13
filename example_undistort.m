img = imread('example_data/Image1.tif');

%Hankin valmiit gridipisteet calib_gui:sta
k = load('example_data/subpixel_x');
kk = load('example_data/Calib_Results');
x = k.x; %Vääristyneet pisteet
X = kk.X_1(1:2,:); %Tasaiset gridipisteet ("reaalimaailman koordinaatit)
%x = [x;ones(1,size(x,2))]; %Muokataan sopivaan muotoon (minun funktioni kaipaavat pisteet ns. homogeenisinä kordinaatteina viimeinen komponentti 1))
X = [X;ones(1,size(X,2))];

%For normalized distortion parameters, uncomment following 3 lines and 
%sections with "%For normalized distortion, uncomment this line" (also in example_rad_lsqmin_fun)
siz = size(img);
%x(1,:) = x(1,:)./siz(2);
%x(2,:) = x(2,:)./siz(1);

%x ja X vastaavat siis toisiaan niin, että X on projisoitu kameramatriisin avulla
%(X:sta on otettu kuva kameralla, jolloin muodostuu kuvapisteet x)

%Plotataan alkutilanne
figure(1)
imagesc(img)
colormap gray
hold on
plotp(x)
hold off

%% Varsinainen laskentaosuus
%Esimerkki minimoinnista
H = makeH(x,X); %Lasketaan homography (tämä on kahden tason välinen projektio)
%nyt inv(H)*X == x
%ja H*x == X (mutta vain skaalaan asti, wnorm(inv(H)*X) == x (hoitaa skaalauksen))

%Pyrimme minimoimaan virheen wnorm(H*x)-X muuttamalla vääristymäparametreja
err = sum(sum((wnorm(H*x)-X).^2))

%Oletetaan vääristymän keskipisteen olevan kuvan keskipisteessä
c = [size(img,2) size(img,1)]/2; %[x y]
%c = c./siz([2 1]); %For normalized distortion, uncomment this line
%Painotan eri parametreja hieman eri tavoin.
%Jos painotukset poistetaan, ei kolmatta radiaalivääristymän kerrointa kannata käyttää

%Nollien määrää muuttamalla voidaan minimointia hieman muokata
r = [0 0 0]; %Vääristymäparametrit oletetaan aluksi nolliksi
t = [0 0];
tc = c;
r = r.*(10.^(1:3:(numel(r)*3))); %Tämähän on aivan turha, mutta esimerkin vuoksi
sx = 1;
para = [c(:)./1e4;sx;t(:);tc(:);r(:)]; %Parametrit vektoriin %For normalized distortion, comment this line
%para = [c(:);sx;r(:)]; %Parametrit vektoriin  %For normalized distortion, uncomment this line

%Suoritetaan minimointi
para(:) = lsqnonlin(@(p)example_rad_lsqmin_fun(X,x,p),para(:),[],[],optimset('TolX',1e-19,'TolFun',1e-19,'Algorithm','levenberg-marquardt','Display','iter'));

%Joten nyt...
c(:) = para(1:2).*1e4; %Radiaalivääristymän keskipiste %For normalized distortion, comment this line
%c(:) = para(1:2); %Radiaalivääristymän keskipiste %For normalized distortion, uncomment this line
sx = para(3);
t(:) = para(4:5);
tc(:) = para(6:7);
r(:) = para(2+1+2+2 +1:end); %Radiaalivääristymän kertoimet
r = r./(10.^(1:3:(numel(r)*3))); %For normalized distortion, comment this line

x_undistorted = undistort(x,r,c,sx,t,tc); %Korjaillaan vääristymää

H = makeH(x_undistorted,X); %Lasketaan homography
err_undistorted = sum(sum((wnorm(H*x_undistorted)-X).^2)) %Huomattavasti pienempi virhe kuin aikaisemmin
%% 

%Turhia plottauksia
% figure(1)
% subplot(1,2,1)
% axis equal
% plotp(x)
% subplot(1,2,2)
% plotp(x_undistorted)
% axis equal

%Nyt voidaan korjata kuva (huom vain mustavalkokuvalle, värikuville tarvitaan looppi)
[x_img y_img] = meshgrid(1:size(img,2),1:size(img,1)); %Alkuperäiset kuvakoordinaatit
%x_img = x_img./siz(2); %For normalized distortion, uncomment this line
%y_img = y_img./siz(1); %For normalized distortion, uncomment this line
X_img = [x_img(:) y_img(:) ones(numel(x_img),1)]';
X_img = distort(X_img,r,c,sx,t,tc); %...vääristetään (käänteisoperaatio undistortille/korjaukselle)
x_uimg = reshape(X_img(1,:),size(img,1),size(img,2)); %Koordinaattien "irroittaminen" matriisista
y_uimg = reshape(X_img(2,:),size(img,1),size(img,2));
Z = interp2(x_img, y_img,single(img),x_uimg,y_uimg); %Suoritetaan kuvan korjaus interpoloimalla

figure(3)
imagesc(img) %Alkuperäinen kuva
colormap gray
figure(2)
imagesc(Z) %Korjattu kuva
colormap gray

imwrite(uint8(Z),'korjattu.tif');
%% Simuloitu esimerkki
[x_ y_] = meshgrid(1:10:640,1:10:480);
x = [x_(:) y_(:) ones(numel(x_),1)]';
x_dist = distort(x,r,c,sx,t,tc);
x_undist = undistort(x_dist,r,c,sx,t,tc);
%x_undist-x;
figure(1)
plotp(x_dist)
figure(2)
plotp(x_undist)

%% Simuloitu esimerkki2
[x_ y_] = meshgrid(1:10:640,1:10:480);
x = [x_(:) y_(:) ones(numel(x_),1)]';
x_dist = distort(x,r,c);
x_undist = undistort(x_dist,r,c);
%x_undist-x;
plotp(x_undist)
%plotp(x_dist)

%% Simuloitu esimerkki 3 (vääristetään ja optimoidaan)
[x_ y_] = meshgrid(1:10:640,1:10:480);
x_org = [x_(:) y_(:) ones(numel(x_),1)]';
x_dist = distort(x_org,r,c,sx,t,tc);

%Oletetaan vääristymän keskipisteen olevan kuvan keskipisteessä
c_ex3 = c+randn(size(c))*1; %[x y] %Vääristymän keskipisteen alkuarvauksen pitää olla melko tarkka
%c = c./siz([2 1]); %For normalized distortion, uncomment this line
%Painotan eri parametreja hieman eri tavoin.
%Jos painotukset poistetaan, ei kolmatta radiaalivääristymän kerrointa kannata käyttää

%Nollien määrää muuttamalla voidaan minimointia hieman muokata
r_ex3 = [0 0 0]; %Vääristymäparametrit oletetaan aluksi nolliksi
t_ex3 = [0 0];
tc_ex3 = c_ex3;
r_ex3 = r_ex3.*(10.^(1:3:(numel(r_ex3)*3))); %Tämähän on aivan turha, mutta esimerkin vuoksi
sx_ex3 = 1;
para_ex3 = [c_ex3(:)./1e4;sx_ex3;t_ex3(:);tc_ex3(:);r_ex3(:)]; %Parametrit vektoriin %For normalized distortion, comment this line
%para = [c(:);sx;r(:)]; %Parametrit vektoriin  %For normalized distortion, uncomment this line

%Suoritetaan minimointi
para_ex3(:) = lsqnonlin(@(p)example_rad_lsqmin_fun(x_org,x_dist,p),para_ex3(:),[],[],optimset('TolX',1e-19,'TolFun',1e-19,'Algorithm','levenberg-marquardt','Display','iter'));

%Joten nyt...
c_ex3(:) = para_ex3(1:2).*1e4; %Radiaalivääristymän keskipiste %For normalized distortion, comment this line
%c(:) = para(1:2); %Radiaalivääristymän keskipiste %For normalized distortion, uncomment this line
sx_ex3 = para_ex3(3);
t_ex3(:) = para_ex3(4:5);
tc_ex3(:) = para_ex3(6:7);
r_ex3(:) = para_ex3(2+1+2+2 +1:end); %Radiaalivääristymän kertoimet
r_ex3 = r_ex3./(10.^(1:3:(numel(r_ex3)*3))); %For normalized distortion, comment this line

x_undistorted = undistort(x_dist,r_ex3,c_ex3,sx_ex3,t_ex3,tc_ex3); %Korjaillaan vääristymää

%x_undist-x;
figure(1)
plotp(x_org)
hold on
H = makeH(x_undistorted,x_org); %"Oikaistaan" kuvaa
plotp(H*x_undistorted,[],'b.')
hold off

%%
%Esimerkki "käänteisestä" minimoinnista
%Tarvitsemme "reaalimaailman pisteet X jotka ovat läheltä kuvan pisteitä x
n = [12 13];
[X_x X_y] = meshgrid(linspace(min(x(1,:)),max(x(1,:)),n(2)), linspace(min(x(2,:)),max(x(2,:)),n(1)));
X = [X_x(:) X_y(:) ones(numel(X_x),1)]';
H = makeH(x,X); %Lasketaan homography (tämä on kahden tason välinen projektio)
%nyt inv(H)*X == x
%ja H*x == X (mutta vain skaalaan asti, wnorm(inv(H)*X) == x (hoitaa skaalauksen))

%Pyrimme minimoimaan virheen wnorm(H*x)-X muuttamalla vääristymäparametreja
err = sum(sum((wnorm(H*x)-X).^2))

%Oletetaan vääristymän keskipisteen olevan kuvan keskipisteessä
c = [size(img,2) size(img,1)]/2; %[x y]
%c = c./siz([2 1]); %For normalized distortion, uncomment this line
%Painotan eri parametreja hieman eri tavoin.
%Jos painotukset poistetaan, ei kolmatta radiaalivääristymän kerrointa kannata käyttää

%Nollien määrää muuttamalla voidaan minimointia hieman muokata
r = [0 0 0]; %Vääristymäparametrit oletetaan aluksi nolliksi
t = [0 0];
tc = c;
r = r.*(10.^(1:3:(numel(r)*3))); %Tämähän on aivan turha, mutta esimerkin vuoksi
sx = 1;
para = [c(:)./1e4;sx;t(:);tc(:);r(:)]; %Parametrit vektoriin %For normalized distortion, comment this line
%para = [c(:);sx;r(:)]; %Parametrit vektoriin  %For normalized distortion, uncomment this line

%Suoritetaan minimointi
para(:) = lsqnonlin(@(p)example_rad_lsqmin_fun_inv(X,x,p),para(:),[],[],optimset('TolX',1e-19,'TolFun',1e-19,'Algorithm','levenberg-marquardt','Display','iter'));

%Joten nyt...
c(:) = para(1:2).*1e4; %Radiaalivääristymän keskipiste %For normalized distortion, comment this line
%c(:) = para(1:2); %Radiaalivääristymän keskipiste %For normalized distortion, uncomment this line
sx = para(3);
t(:) = para(4:5);
tc(:) = para(6:7);
r(:) = para(2+1+2+2 +1:end); %Radiaalivääristymän kertoimet
r = r./(10.^(1:3:(numel(r)*3))); %For normalized distortion, comment this line

X_distorted = distort(X,r,c,sx,t,tc); %Korjaillaan vääristymää

H = makeH(x,X_distorted); %Lasketaan homography
err_undistorted = sum(sum((wnorm(H*x)-X_distorted).^2)) %Huomattavasti pienempi virhe kuin aikaisemmin, mutta ei yhtä hyvä tulos kuin suoralla
%% Nyt voimme tehdä parempilaatuisen interpolaation
%Nyt voidaan korjata kuva (huom vain mustavalkokuvalle, värikuville tarvitaan looppi)
[x_img y_img] = meshgrid(1:size(img,2),1:size(img,1)); %Alkuperäiset kuvakoordinaatit
%x_img = x_img./siz(2); %For normalized distortion, uncomment this line
%y_img = y_img./siz(1); %For normalized distortion, uncomment this line
X_img = [x_img(:) y_img(:) ones(numel(x_img),1)]';
X_img = distort(X_img,r,c,sx,t,tc); %...vääristetään (käänteisoperaatio undistortille/korjaukselle)
x_uimg = reshape(X_img(1,:),size(img,1),size(img,2)); %Koordinaattien "irroittaminen" matriisista
y_uimg = reshape(X_img(2,:),size(img,1),size(img,2));
Z = interp2(x_img, y_img,single(img),x_uimg,y_uimg); %Suoritetaan kuvan korjaus interpoloimalla

figure(3)
imagesc(img) %Alkuperäinen kuva
colormap gray
figure(2)
imagesc(Z) %Korjattu kuva
colormap gray
%% Suora muunnos vain kalibrointilevyn alueelta
n = [12 13]; %Kalibrointilevyn pisteiden lukumäärä [y x]

%Havaittuja pisteitä vastaavat "reaalimaailman" pisteet. Sama määrä kuin
%kalibrointigridissä
[X_x_sparse X_y_sparse] = meshgrid(linspace(0,1,n(2)), linspace(0,1,n(1)));
%Suurempi määrä havaittuja pisteitä (määrää lopullisen tarkkuuden)
%Nyt 30 pix / gridin neliö
[X_x_full X_y_full] = meshgrid(linspace(0,1,n(2)*30), linspace(0,1,n(1)*30));

%Kalibrointilevyn pisteet
k = load('example_data/subpixel_x');
x = k.x; %Vääristyneet pisteet
x_x = reshape(x(1,:),n); %Muutetaan gridimuotoon
x_y = reshape(x(2,:),n);

%Interpoloidaan lisää vääristyneitä pisteitä
%Interpoloinnissa tulee käyttää jotakin muuta interpolointitapaa kuin
%'linear' (muutoin paloittain lineaarinen interpolointi joka ei lainkaan
%sovi linssivääristymän mallintamiseen)
x_x_full = interp2(X_x_sparse,X_y_sparse,x_x,X_x_full,X_y_full,'cubic');
x_y_full = interp2(X_x_sparse,X_y_sparse,x_y,X_x_full,X_y_full,'cubic');

%Kuvan koordinaatit
[img_x img_y] = meshgrid(1:size(img,2),1:size(img,1));

%"Meillä on kuva (img) jonka koordinaatteja kuvaa img_x ja img_y.
%Haluamme saada tästä kuvasta uuden neliskanttisen matriisin, jonka
%alkiot ovat muodostuneet vääristyneen gridin pisteiden perusteella"
%Tässä riittää lineaari-interpolaatio
Z = interp2(img_x,img_y,single(img),x_x_full,x_y_full);
imagesc(Z)
