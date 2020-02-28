% this program is to calculate the number of averagings at each data index
% during a window sum executation in firmware

function ws1 = ws_calculation(N,M,n,x)
N= 200;%total number of recorded data pts
M = 3000; %total number of 180 pulses
n = 50;% reserved index for the first n pts, without data compression
x = 1.03027;

% calculated through: NSolve[Sum[x^ii, {ii, 1, 150}] == 2950, x, Reals] in
% Mathematica

table = ones(N,1)
%
for i = 1:(N-n)
    table(i+n) = round(x^i)
end

sum(table(1:end))  
table(N) = table(N)+1;

sum(table(1:end))  
plot(table,'o')
xlabel('data index')
ylabel('no. of averagings')

ws1 = table;
end


