proc import datafile='C:\Users\Varsha\OneDrive\ABI\project\books.txt'  outt=abiproj.nt (drop=VAR15);
getnames=yes;
run;

proc sql;
create table abiproj.regnt as
select unique(userid), education, region, hhsz, age, income, child, race, country, avg(price) as ppbook, avg(qty) as qtyperv, sum(qty) as qty
from abiproj.nt
where domain = 'barnesandn'
group by userid;
quit;

proc print data=abiproj.regnt(obs=10);
run;

proc sql;
create table abiproj.bn as
select unique(userid), sum(qty) as qty 
from abiproj.nt
where domain in ('barnesandn')
group by userid, domain;
quit;

proc sql;
create table abiproj.nbd_bn as 
select unique(qty) as exposures,count(unique(userid)) as peoplecount
from abiproj.bn
group by qty
order by qty;
quit;

proc print data=abiproj.nbd_bn(obs=10);
run;

/*NBD Model*/
proc NLMIXED data= abiproj.nbd_bn;
parms r=2 alpha=2;
m= ((gamma(r+exposures))/(gamma(r)*fact(exposures)))* ((alpha/(alpha+1))**r)*((1/(alpha+1))**exposures);
ll=peoplecount*log(m);
model peoplecount ~ general(ll);
run;

/*Poisson Regression*/
data abiproj.nt;
set abiproj.nt;
  date_new = input(put(date, 8.), yymmdd8.);
run;

data abiproj.nt;
set abiproj.nt;
wend=0;
if weekday(date_new) = 1 then wend = 1;
if weekday(date_new) = 7 then wend = 1;
run;

proc sql;
create table abiproj.regnt as
select unique(userid), weekday(date) as dayofweek, education, region,hhsz, age, income, child, race, country, avg(price) as ppbook, avg(qty) as qtyperv, sum(qty) as qty, avg(wend) as wend 
from abiproj.nt
where domain = 'barnesandn'
group by userid;
quit;

proc nlmixed data=abiproj.regnt;
 /* m stands for lambda */
 parms m0=1 b1=0 b2=0 b3=0 b4=0 b5=0 b6=0 b7=0 b8=0 b9=0;
 m=m0*exp(b1*education+b2*hhsz+b3*age+b4*income+b5*child+b6*country+b7*ppbook+b8*qtyperv+b9*wend);
 ll = qty*log(m)-m-log(fact(qty));
 model qty ~ general(ll);
run;

/*NBD Regression*/
proc nlmixed data=abiproj.regnt;
parms r=1 alpha=1 b1=0 b2=0 b3=0 b4=0 b5=0 b6=0 b7=0 b8=0 b9=0;
prob=exp(b1*education+b2*hhsz+b3*age+b4*income+b5*child+b6*country+b7*ppbook+b8*qtyperv+b9*wend);
m=((gamma(r+qty))/(gamma(r)*fact(qty)))* ((alpha/(alpha+prob))**r)* (prob/(alpha+prob))**qty;
ll = log(m);
model qty ~ general(ll);
run;
