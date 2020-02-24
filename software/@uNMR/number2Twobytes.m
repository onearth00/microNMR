function [res] = number2Twobytes(obj,DATA)

k = floor(length(DATA));
res = [];
for ii=1:k
    res = [res Anumber2Twobytes(DATA(ii))];
end

end




function res = Anumber2Twobytes(DATA)

        % just take the first data and turn it into two-byte hex
        res(1) = floor(DATA(1)/256);
        res(2) = mod(floor(DATA(1)),256);        
end