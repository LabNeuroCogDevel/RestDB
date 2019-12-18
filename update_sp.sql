create temporary table spt(
    sp_mean float,
    sp_path text,
    ts4d text);

.mode csv
.import txt/update_sp.txt spt

update rest
  set sp_mean = (select sp_mean from spt where spt.ts4d = rest.ts4d)
  where sp_mean is null;

update rest
  set sp_path = (select sp_path from spt where spt.ts4d = rest.ts4d)
  where sp_path is null;
