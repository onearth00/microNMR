function nmrplot(indata,t2)
% plot NMR data, real - red, imag - blue, amp - black
% work for 2D data
% function nmrplot(indata,t2)
nd = size(indata);

if nargin == 1
    t = (1:nd(1))-1;
else
    if length(t2) == nd(1)
        t = real(t2);
    else
        t = ((1:nd(1))-1)*t2(1);
    end
end

plot(t, real(indata),'r.-')
hold on
plot(t,imag(indata), 'b.-')
%plot(t,abs(indata),'k.-')

hold off

return

