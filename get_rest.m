% GET_REST(dbcn,sqlwherequery) - query rest optionally with the where part of
% query. includes age and sex merged from ses table
%
% USAGE:
%  get_rest(dbcn) % all rest
%  get_rest(dbcn,'study like "cog" and preproc like "aroma"') % cog aroma
%
function t = get_rest(dbcn,varargin)
  varnames = {'ses_id','study','preproc','atlas','ntr','ts_file',...
              'adj_file',...
              'motion_n_cens','motion_pct_cens','motion_path','fd_mean',...
              'fd_median','fd_n_cens','fd_path','dvars_mean',...
              'dvars_median','dvars_n_cens','dvars_path'};
  
  sqlquery = 'select ses.subj, ses.age, ses.sex, ses.dx, rest.* from rest natural join ses';
  if ~isempty(varargin)
        sqlquery = [sqlquery ' where ' varargin{1}];
  end
  ses = fetch(dbcn,sqlquery);
  if isempty(ses)
      ses = cell(0,length(varnames)+3);
  end
  t = cell2table(ses,'VariableNames',{'subj', 'age','sex','dx', varnames{:}});  
end