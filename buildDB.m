% buildDB -- (re)build database from already generated mat/*rest.mat files
function buildDB()
%% iniailze mats
% this would take a long time. done once. dont need to do again
% ...until there is new data. but maybe just do one of them
%build_db_mats()

%% open db
dbcn = sqlite('rest.db');

%% insert each matfile
% remove all old data 
exec(dbcn,'delete from ses');
exec(dbcn,'delete from rest');
% replace will all new data
matfiles = dir('mats/*rest.mat');
for mati = 1:length(matfiles)
    % put humpty dumpty fullty pathty back together again
    f = fullfile(matfiles(mati).folder, matfiles(mati).name);
    % get e.g. 'cog' from 'cogrest.mat' (by removing last 8 character of
    % filename)
    studyname=matfiles(mati).name(1:end-8);
    disp(studyname)
    % add to db with study name for ses, also remove duplicates
    mat_to_db(f,dbcn,studyname)
end

return

%% query -- example full query
sqlquery = 'select * from rest where ses_id like "10124_20060803"';
data = fetch(dbcn,sqlquery)

%% query with helper -- returns table
onedata = get_rest(dbcn,'ses_id like "10124_20060803"')

%% query: find bad rows
ses = get_ses(dbcn);
bad_rows = ses(ses.age < 8 | ses.age > 35 | ~ismember(ses.sex,{'M','F'}) ,:);

%% end: close db handler
close(dbcn)

end
