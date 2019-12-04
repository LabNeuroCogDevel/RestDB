-- improved schema with atlas info separated from pipeline metrics (fd, dvars, sp) 
-- would need to rewrite matlab *.mat files to insert
-- created 20190502, still unimplemented 20191204

-- session info
create table ses (
   -- likely subj_ymd
   ses_id varchar(50) primary key, 
   study varchar(10),  -- delete from ses where study = ...
   age float,
   -- properties of scan
   ntr integer,
   -- stuff that is repeated
   subj varchar(50),
   sex varchar(1),
   dx varchar(10)
);

-- pipeline info
create table pipe (
    ses_id varchar(50) not null,
    study varchar(10),
    preproc varchar(20),
    -- location of timesieres nifti
    ts_file text,

    -- motion
    motion_n_cens float,
    motion_pct_cens float,
    motion_path text,

    -- fd 
    fd_mean float,
    fd_median float,
    fd_n_cens integer,
    fd_path text,

    -- dvars
    dvars_mean float,
    dvars_median float,
    dvars_n_cens integer,
    dvars_path text,

    -- mean spike percentage (wavelet despiking)
    sp_mean float,
    sp_path text,


    -- connect to ses
    foreign key (ses_id, study) references ses (ses_id, study)
);

-- connectivity matrix location
create table rest (
    -- likely subj_ymd
    ses_id varchar(50) not null,
    study varchar(10),
    preproc varchar(20),
    atlas varchar(10),

    -- location of corr mat
    adj_file text, 

    -- relation to preproc table
    foreign key (ses_id, study, prepoc) references pipe (ses_id, study, preproc)
);

create table tsnr (
    ses_id varchar(50) not null,
    study varchar(10),
    preproc varchar(20),

    isfinal boolean default false,
    roi text, -- default gm
    prefix text,
    input text,
    step numeric,
    tsnr  numeric,

    -- relation to preproc table
    foreign key (ses_id, study, prepoc) references pipe (ses_id, study, preproc)
);

