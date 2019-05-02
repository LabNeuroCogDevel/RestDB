function [atlases] = atlas_list(study)
 atlases = { 'GordonHarOx', 'hpc_pfc_brainstem_rstg', 'CogEmoROIs', 'cogemo20181220', 'vmpfcstrvta20181221', 'hpc_apriori_atlas_11','wb1038'}
 % before 20190107, in each *rest_table.m as:
 %  cog => {'GordonHarOx', 'hpc_pfc_brainstem_rstg','CogEmoROIs'};
 %  pet => {'GordonHarOx','CogEmoROIs','vmpfcstrvta20181221'};
 %  pnc => {'GordonHarOx', 'hpc_apriori_atlas_11','hpc_pfc_brainstem_rstg','CogEmoROIs'};
 %  rew => {'GordonHarOx','CogEmoROIs'};
end
