function [ppd] = nmrlist(datadir)
%
% list all data in one directory, incl pulse seq and title

fulldir = dir(datadir);
myindex = 1;

for ii = 1:length(fulldir)
   dataindex = str2num(fulldir(ii).name);

   
   if dataindex >= 1
       
       [p]=readbrukerParameters(datadir,dataindex);
       ppd(myindex) = p;
       myindex = myindex+1;
   else
       disp 'not data'
       
   end
end

for ii = 1:length(ppd)
    
    fprintf(1,'\n\n')
    fprintf(1,'expno %d\n',ii);
    fprintf(1, 'seq  : %s\n',ppd(ii).ppg);
    fprintf(1, 'title: %s\n',ppd(ii).title);

end 

return