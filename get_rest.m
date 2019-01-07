% GET_REST(dbcn,sqlwherequery) - query rest optionally with the where part of
% query. includes age and sex merged from ses table
%
% USAGE:
%  dbcn = sqlite('rest.db');
%  get_rest(dbcn) % all rest
%  get_rest(dbcn,'study like "cog" and preproc like "aroma"') % cog aroma
%
function t = get_rest(dbcn,varargin)
  
  varnames = {'ses_id','study','preproc','atlas','ntr','ts_file',...
              'adj_file',...
              'motion_n_cens','motion_pct_cens','motion_path','fd_mean',...
              'fd_median','fd_n_cens','fd_path','dvars_mean',...
              'dvars_median','dvars_n_cens','dvars_path'};
  restselect = cell2mat(cellfun(@(x) ['rest.' x ', '],varnames,'UniformOutput',0));
  
  sqlquery = ['select ',...
             'ses.subj, ses.age, ses.sex, ses.dx, '...
             restselect ,...
             ' case when tsnr.tsnr > 0 then tsnr.tsnr else -1 end',...
             ' from rest natural join ses', ...
             ' left join tsnr on tsnr.isfinal=1 and tsnr.ses_id = rest.ses_id and tsnr.preproc = rest.preproc and tsnr.study = rest.study'];
  if ~isempty(varargin)
        sqlquery = [sqlquery ' where ' varargin{1}];
  end
  ses = fetch(dbcn,sqlquery);
  if isempty(ses) || all(size(ses)==0)
      ses = cell(0,length(varnames)+5);
  end
  %ses
  t = cell2table(ses,'VariableNames',{'subj', 'age','sex','dx', varnames{:}, 'tsnr'});  
end
