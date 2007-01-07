-- to build spec #{owner} needs #{require}-#{version}-#{release}
create table buildreq_tbl (
       owner integer not null,

       require text,
       version text default null,
       release text default null,
       epoch   text default null
);

-- spec #{owner} generates  #{package}-#{version}-#{release}.?.rpm
create table package_tbl (
       owner integer not null,

       package text primary key,
       version text default null,
       release text default null,
       epoch   text default null
);

-- #{package} require #{requires}-#{version}-#{requires}
create table require_tbl (
       owner integer not null,
       package text,

       require text,
       version text default null,
       release text default null,
       epoch   text default null
);

-- #{package} provides #{provide}
create table provide_tbl (
       owner integer not null,
       package text,

       provide text
);

create table specfile_tbl (
       id integer primary key autoincrement,
       name text unique not null,
       lastupdate integer
);
