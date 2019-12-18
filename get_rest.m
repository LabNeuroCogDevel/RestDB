% GET_REST(dbcn,sqlwherequery) - query rest optionally with the where part of
% query. includes age and sex merged from ses table
%
% USAGE:
%  dbcn = sqlite('rest.db');
%  get_rest(dbcn) % all rest
%  get_rest(dbcn,'study like "cog" and preproc like "aroma"') % cog aroma
%
function t = get_rest(dbcn,varargin)

  % TODO: dont require dbcn
  % if nargin == 0
  %  dcbn=sqlite('rest.db');
  % elsif strmatch(class(dbcn),'sqlite??')
  %  dcbn=sqlite('rest.db');
  %  varargin={dbcn,varargin{:})
  % end
  
  varnames = {'ses_id','study','preproc','atlas','ntr','ts_file',...
              'adj_file',...
              'motion_n_cens','motion_pct_cens','motion_path','fd_mean',...
              'fd_median','fd_n_cens','fd_path','dvars_mean',...
              'dvars_median','dvars_n_cens','dvars_path'};
  restselect = cell2mat(cellfun(@(x) ['rest.' x ', '],varnames,'UniformOutput',0));
  
  sqlquery = ['select ',...
             'ses.subj, ses.age, ses.sex, ses.dx, '...
             restselect ,...
             ' case when rest.sp_mean > 0 then rest.sp_mean else -1 end, ',...
             ' case when tsnr.tsnr > 0 then tsnr.tsnr else -1 end',...
             ' from rest natural join ses', ...
             ' left join tsnr on tsnr.isfinal=1 and tsnr.ses_id = rest.ses_id and tsnr.preproc = rest.preproc and tsnr.study = rest.study'];
  if ~isempty(varargin)
        whereclause = varargin{1};
        %% fix issues with needed rest/tsr table specified
        % whereclause = 'study rest.study "mystudy" "foopreprocbar" preproc tstr.preproc';
        whereclause = regexprep(whereclause,'(^|[^.])\<(study|preproc)\>','$1rest.$2');
        %             = '*rest.study* rest.study "mystudy" "foopreprocbar" *rest.preproc* tstr.preproc'
        if ~startsWith(whereclause, varargin{1})
           warning('unspecified table for study/preproc columns. Prepended "rest." to column names in your query') 
        end

        sqlquery = [sqlquery ' where ' whereclause];
  end
  sqlquery
  ses = fetch(dbcn,sqlquery);
  if isempty(ses) || all(size(ses)==0)
      ses = cell(0,length(varnames)+5);
  end
  %ses
  t = cell2table(ses,'VariableNames',{'subj', 'age','sex','dx', varnames{:},'sp_mean', 'tsnr'});  
end
