

-- session info
create table ses (
   -- likely subj_ymd
   ses_id varchar(50) primary key, 
   study varchar(10),  -- delete from ses where study = ...
   -- stuff that is repeated
   subj varchar(50),
   age float,
   sex varchar(1),
   dx varchar(10)
);

-- connectivity matrix location
create table rest (
    -- likely subj_ymd
    ses_id varchar(50) not null,
    study varchar(10),
    preproc varchar(20),
    atlas varchar(10),

    -- properties
    ntr integer,

    -- metrics --
    adj_file text, -- ROITempCor: location of corr mat
    ts_file text, -- ROITempCor: location of timesieres text
    ts4d text,  --- not set 20180622, nifti

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

    -- relation to session table
    foreign key (ses_id) references ses (ses_id)
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
    -- relation to session table
    foreign key (ses_id) references ses (ses_id)
);
