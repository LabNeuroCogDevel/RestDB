% get_ses(dbconnection,sqlwhere)
% USAGE:
%  get_ses(dbcn) % all sessions
%  get_ses(ddcn,'age >= 13 and age < 20') % all teens
function t = get_ses(dbcn,varargin)
  sqlquery = 'select * from ses ';
  if ~isempty(varargin)
        sqlquery = [sqlquery ' where ' varargin{1}];
  end
  ses = fetch(dbcn,sqlquery);
  if isempty(ses)
      ses = cell(0,5);
  end
  t = cell2table(ses,'VariableNames',{'ses_id','study','subj','age','sex','dx'});
end