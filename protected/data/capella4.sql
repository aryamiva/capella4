SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT=0;
START TRANSACTION;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;


DELIMITER $$
DROP PROCEDURE IF EXISTS `pExecuteImmediate`$$
CREATE DEFINER=`capella4`@`localhost` PROCEDURE `pExecuteImmediate`(IN tSQLStmt TEXT)
BEGIN
  SET @executeImmediateSQL = tSQLStmt;
  PREPARE executeImmediateSTML FROM @executeImmediateSQL;
  EXECUTE executeImmediateSTML;
  DEALLOCATE PREPARE executeImmediateSTML;
END$$

DROP PROCEDURE IF EXISTS `pRaiseError`$$
CREATE DEFINER=`capella4`@`localhost` PROCEDURE `pRaiseError`(sError VARCHAR(255))
BEGIN
        CALL pExecuteImmediate(fFormat('CALL `error: %s', sError));
END$$

DROP FUNCTION IF EXISTS `GetParamValue`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetParamValue`(vParamName text) RETURNS text CHARSET utf8
BEGIN
	declare ret text;
	select paramvalue
	into ret
	from parameter
	where lower(paramname) = lower(vParamName);
	return ret;
END$$

DROP FUNCTION IF EXISTS `GetRunNo`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetRunNo`(vsnroid int,vdate datetime) RETURNS varchar(100) CHARSET utf8
BEGIN
	declare vformatdoc,vformatno,vmr,vrepeatby,vrom varchar(100);
	declare vdd,vmm,vyy,vcurrvalue,lyy,vtrap integer;

	select formatdoc,formatno,repeatby
	into vformatdoc,vformatno,vrepeatby
	from snro
	where snroid = vsnroid;

	select day(vdate) into vdd;
	select month(vdate) into vmm;	
	select year(vdate) into vyy;
	if position('MONROM' in vformatno) then
		select monthrm into vmr
		from romawi
		where monthcal = vmm
    limit 1;
	end if; 

	if (position('YYYY' in vrepeatby) > 0) then
		set lyy = 4;
	else
		if (position('YY' in vrepeatby) > 0) then
			set lyy = 2;
		end if;
	end if;

  if (vrepeatby = '') then
		select ifnull(count(1),0)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid;
    set vtrap = 4;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid
      limit 1;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,0,0,0,1);
		end if;
  else
if (position('DD' in vrepeatby) > 0) and
	   (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) then
		select ifnull(count(1),0)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy;
set vtrap = 3;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy
      limit 1;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,vdd,vmm,vyy,1);
		end if;
  else
if (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) then
set vtrap = 2;
		select ifnull(count(1),0)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curmm = vmm and curyy = vyy;


		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curmm = vmm and curyy = vyy
      limit 1;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curmm = vmm and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,0,vmm,vyy,1);
		end if;
  else
	if (position('YY' in vrepeatby) > 0) then
		select ifnull(count(1),0)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curyy = vyy;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curyy = vyy
      limit 1;

			set vcurrvalue=vcurrvalue + 1;
			
			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,0,0,vyy,1);
		end if;
  end if;

  end if;

  end if;
	end if;


	select concat(abc,substring(formatdoc,length(abc)+1)) 
	into vformatdoc
	from (
	select formatdoc,formatno, concat(left(formatdoc,position(formatno in formatdoc)-1),
	concat(left(formatno,length(formatno)-length(angka)),angka))
	as abc
	from (
	select vcurrvalue as angka, formatdoc, formatno 
	from snro where snroid = vsnroid
	) a ) b;

	if vdd < 10 then
		select replace(vformatdoc,'DD',concat('0',vdd)) into vformatdoc;
	else
		select replace(vformatdoc,'DD',vdd) into vformatdoc;
	end if;

	if vmm < 10 then
		select replace(vformatdoc,'MM',concat('0',vmm)) into vformatdoc;
	else
		select replace(vformatdoc,'MM',vmm) into vformatdoc;
	end if;
	
	if (position('YY' in vrepeatby) > 0) then
		if lyy = 4 then
			select replace(vformatdoc,'YYYY',vyy) into vformatdoc;
		else
		if lyy = 2 then
			select replace(vformatdoc,'YY',right(vyy,lyy)) into vformatdoc;
		end if;	
		end if;
	else
		select replace(vformatdoc,'YY',right(vyy,2)) into vformatdoc;
	end if;

	if (position('MONROM' in vformatdoc) > 0) then
		select monthrm 
		into vrom 
		from romawi
		where monthcal = vmm
    limit 1;
		select replace(vformatdoc,'MONROM',vrom) into vformatdoc;
	end if;

	return vformatdoc;
END$$

DROP FUNCTION IF EXISTS `GetRunNoSp`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetRunNoSp`(vsnroid int,
vdate datetime,vCC varchar(5), vPT varchar(5), vPP varchar(5) ) RETURNS varchar(100) CHARSET utf8
BEGIN
	declare vformatdoc,vformatno,vmr,vrepeatby,vrom varchar(100);
	declare vdd,vmm,vyy,vcurrvalue,lyy integer;
	select formatdoc,formatno,repeatby
	into vformatdoc,vformatno,vrepeatby
	from snro
	where snroid = vsnroid;
	
	select day(vdate) into vdd;
	select month(vdate) into vmm;	
	select year(vdate) into vyy;
	if position('MONROM' in vformatno) then
		select monthrm into vmr 
		from romawi
		where monthcal = vmm;
	end if;

	if (position('YYYY' in vrepeatby) > 0) then
		set lyy = 4;
	else
		if (position('YY' in vrepeatby) > 0) then
			set lyy = 2;
		end if;
	end if;
	
if (vrepeatby = '') then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue, curcc,curpt,curpp)
			values (vsnroid,0,0,0,1,vcc,vpt,vpp);
		end if;
else
if (position('MT' in vrepeatby) > 0) and
	   (position('PMG' in vrepeatby) > 0) and
	   (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) and
	   (position('MGO' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue,curcc,curpt,curpp)
			values (vsnroid,vdd,vmm,vyy,1,vcc,vpt,vpp);
		end if;
  else
if (position('MT' in vrepeatby) > 0) and
	   (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) and
	   (position('MGO' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt;

			set vcurrvalue=vcurrvalue + 1;

			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue,curcc,curpt)
			values (vsnroid,vdd,vmm,vyy,1,vcc,vpt);
		end if;
  else
if (position('CC' in vrepeatby) > 0) and
	   (position('PT' in vrepeatby) > 0) and
	   (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) and
	   (position('PP' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;

			set vcurrvalue=vcurrvalue + 1;
			
			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy and
       curcc = vcc and curpt = vpt and curpp = vpp;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue,curcc,curpt,curpp)
			values (vsnroid,vdd,vmm,vyy,1,vcc,vpt,vpp);
		end if;
  else
if (position('DD' in vrepeatby) > 0) and
	   (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy;

			set vcurrvalue=vcurrvalue + 1;
			
			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curdd = vdd and curmm = vmm and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,vdd,vmm,vyy,1);
		end if;
	else
if (position('MM' in vrepeatby) > 0) and
	   (position('YY' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curmm = vmm and curyy = vyy;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curmm = vmm and curyy = vyy;

			set vcurrvalue=vcurrvalue + 1;
			
			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curmm = vmm and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,0,vmm,vyy,1);
		end if;	
	else
	if (position('YY' in vrepeatby) > 0) then
		select count(1)
		into vcurrvalue
		from snrodet
		where snroid = vsnroid and curyy = vyy;

		if vcurrvalue > 0 then
			select curvalue
			into vcurrvalue
			from snrodet
			where snroid = vsnroid and curyy = vyy;

			set vcurrvalue=vcurrvalue + 1;
			
			update snrodet
			set curvalue = vcurrvalue
			where snroid = vsnroid and curyy = vyy;
		else
			set vcurrvalue=1;
			insert into snrodet (snroid,curdd,curmm,curyy,curvalue)
			values (vsnroid,0,0,vyy,1);
		end if;


	end if;	
	end if; 
	end if;
	end if;
end if;
end if;
end if;

	

	select concat(abc,substring(formatdoc,length(abc)+1)) 
	into vformatdoc
	from (
	select formatdoc,formatno, concat(left(formatdoc,position(formatno in formatdoc)-1),
	concat(left(formatno,length(formatno)-length(angka)),angka))
	as abc
	from (
	select vcurrvalue as angka, formatdoc, formatno 
	from snro where snroid = vsnroid
	) a ) b;

	if vdd < 10 then
		select replace(vformatdoc,'DD',concat('0',vdd)) into vformatdoc;
	else
		select replace(vformatdoc,'DD',vdd) into vformatdoc;
	end if;

	if vmm < 10 then
		select replace(vformatdoc,'MM',concat('0',vmm)) into vformatdoc;
	else
		select replace(vformatdoc,'MM',vmm) into vformatdoc;
	end if;
	
	if (position('YY' in vrepeatby) > 0) then
		if lyy = 4 then
			select replace(vformatdoc,'YYYY',vyy) into vformatdoc;
		else
		if lyy = 2 then
			select replace(vformatdoc,'YY',right(vyy,lyy)) into vformatdoc;
		end if;	
		end if;
	else
		select replace(vformatdoc,'YY',right(vyy,2)) into vformatdoc;
	end if;

	if (position('MONROM' in vformatdoc) > 0) then
		select monthrm 
		into vrom 
		from romawi
		where monthcal = vmm;
		select replace(vformatdoc,'MONROM',vrom) into vformatdoc;
	end if;

  if (position('CC' in vformatdoc) > 0) then
    select replace(vformatdoc,'CC',vcc) into vformatdoc;
  end if;

  if (position('PT' in vformatdoc) > 0) then
    select replace(vformatdoc,'PT',vpt) into vformatdoc;
  end if;


  if (position('PP' in vformatdoc) > 0) then
    select replace(vformatdoc,'PP',vpp) into vformatdoc;
  end if;

  if (position('MT' in vformatdoc) > 0) then
    select replace(vformatdoc,'MT',vcc) into vformatdoc;
  end if;

  if (position('MGO' in vformatdoc) > 0) then
    select replace(vformatdoc,'MGO',vpt) into vformatdoc;
  end if;


  if (position('PMG' in vformatdoc) > 0) then
    select replace(vformatdoc,'PMG',vpp) into vformatdoc;
  end if;

	return vformatdoc;
END$$

DROP FUNCTION IF EXISTS `GetWfBefStat`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWfBefStat`(vwfname varchar(50), 
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vreturn int;
	select b.wfbefstat
	into vreturn
	from assignments a
	inner join wfgroup b on upper(b.items) = upper(a.itemname)
	inner join workflow c on c.workflowid = b.workflowid
	where a.userid = vcreatedby and upper(c.wfname) = upper(vwfname);

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWfBefStatByCreated`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWfBefStatByCreated`(vwfname varchar(50),
vbefstat tinyint,
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vreturn int;

  select ifnull(count(1),0)
	into vreturn
	from usergroup a
  inner join useraccess d on d.useraccessid = a.useraccessid
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) and b.wfbefstat = vbefstat;

  if vreturn > 0 then
	select b.wfgroupid
	into vreturn
	from usergroup a
  inner join useraccess d on d.useraccessid = a.useraccessid
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) and b.wfbefstat = vbefstat;
  end if;

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWFCompareMax`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWFCompareMax`(vwfname varchar(50),
vnextstat int,
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vrecstat,vmaxstat,vreturn int;
	select distinct b.wfrecstat,c.wfmaxstat
	into vrecstat,vmaxstat
	from usergroup a
  inner join useraccess d on d.useraccessid = a.useraccessid
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) and b.wfbefstat = vnextstat-1;

	if vnextstat = vmaxstat then
		set vreturn = 1;
	else
		set vreturn = 0;
	end if;

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWFCompareMinApp`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWFCompareMinApp`(vwfname varchar(50),
vnextstat int,
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vrecstat,vmaxstat,vreturn int;
	select b.wfrecstat,c.wfminstat
	into vrecstat,vmaxstat
	from usergroup a
  inner join useraccess d on d.useraccessid = a.useraccessid
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) limit 1;


	if vnextstat = vmaxstat then
		set vreturn = 1;
	else
		set vreturn = 0;
	end if;

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWfMaxStatByWfName`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWfMaxStatByWfName`(vwfname varchar(50)) RETURNS int(11)
BEGIN
	declare vreturn int;

	select ifnull(count(1),0)
	into vreturn
	from workflow c
	where upper(c.wfname) = upper(vwfname);

  if vreturn > 0 then
	  select c.wfmaxstat
	  into vreturn
	  from workflow c
	  where upper(c.wfname) = upper(vwfname);
  end if;

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWfMinStatByWfName`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWfMinStatByWfName`(vwfname varchar(50),vcreatedby integer) RETURNS int(11)
BEGIN
	declare vreturn int;
	select c.wfminstat
	into vreturn
	from usergroup a
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where a.useraccessid = vcreatedby and upper(c.wfname) = upper(vwfname);

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWfNextStatByCreated`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWfNextStatByCreated`(vwfname varchar(50), 
vbefstat tinyint,
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vreturn int;
	select ifnull(b.wfgroupid,0)
	into vreturn
	from assignments a
	inner join wfgroup b on upper(b.items) = upper(a.itemname)
	inner join workflow c on c.workflowid = b.workflowid
	where a.userid = vcreatedby and upper(c.wfname) = upper(vwfname) and b.wfrecstat = vbefstat;

	return vreturn;
END$$

DROP FUNCTION IF EXISTS `GetWFRecStatByCreated`$$
CREATE DEFINER=`capella4`@`localhost` FUNCTION `GetWFRecStatByCreated`(vwfname varchar(50),
vbefstat tinyint,
vcreatedby varchar(50)) RETURNS int(11)
BEGIN
	declare vreturn int;

  select ifnull(count(1),0)
  into vreturn
	from usergroup a
  inner join useraccess d on d.useraccessid = a.useraccessid
	inner join wfgroup b on b.groupaccessid = a.groupaccessid
	inner join workflow c on c.workflowid = b.workflowid
	where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) and b.wfbefstat = vbefstat;

  if vreturn > 0 then
	  select b.wfrecstat
	  into vreturn
	  from usergroup a
    inner join useraccess d on d.useraccessid = a.useraccessid
	  inner join wfgroup b on b.groupaccessid = a.groupaccessid
	  inner join workflow c on c.workflowid = b.workflowid
	  where upper(d.username) = upper(vcreatedby) and upper(c.wfname) = upper(vwfname) and b.wfbefstat = vbefstat;
  end if;
	return vreturn;
END$$

DELIMITER ;

DROP TABLE IF EXISTS `catalogsys`;
CREATE TABLE IF NOT EXISTS `catalogsys` (
  `catalogsysid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `languageid` int(11) NOT NULL,
  `messagesid` int(10) unsigned NOT NULL,
  `catalogval` text NOT NULL,
  `recordstatus` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`catalogsysid`),
  KEY `FK_catalogsys_mess` (`messagesid`),
  KEY `ix_catalogsys` (`languageid`,`messagesid`,`catalogsysid`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=38 ;

INSERT INTO `catalogsys` (`catalogsysid`, `languageid`, `messagesid`, `catalogval`, `recordstatus`) VALUES
(1, 1, 1, 'Nama Perusahaan', 1),
(2, 1, 2, 'Aktif', 1),
(3, 1, 3, 'Tidak Aktif', 1),
(4, 1, 4, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Company digunakan untuk menentukan nama perusahaan beserta data tentang perusahaan.</p>\r\n<h1 class="h1help">Relasi</h1> <p class="phelp">Data Company digunakan di modul : Header Report, Data Transaksi untuk base currency</p>\r\n</div>', 1),
(5, 1, 5, 'Akses User', 1),
(6, 1, 6, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul User Access digunakan user untuk memasukkan data pengguna Capella. <br/>\r\nData yang dimasukkan adalah username, password, realname, employee</p>\r\n<h1 class="h1help">Relasi</h1> <p class="phelp">Data User Access digunakan di modul : User Group, User Login</p>\r\n</div>', 1),
(7, 1, 7, 'Menu', 1),
(8, 1, 8, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Menu Access digunakan untuk mendaftarkan menu yang diakses oleh user</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Menu Access digunakan di modul : Group Menu, Menu Object/ Authentication</p>\r\n</div>', 1),
(9, 1, 9, 'Otorisasi Objek Menu', 1),
(10, 1, 10, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Menu Auth digunakan untuk mencatat otorisasi per object data yang ada di modul lain</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Menu Auth digunakan di modul Form Request, Purchase Request, Purchase Order, Goods Received, Goods Issue</p>\r\n</div>', 1),
(11, 1, 11, 'Grup Akses', 1),
(12, 1, 12, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Group Access digunakan untuk mendaftarkan group</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Group Access digunakan di modul Group Menu, Workflow Group</p>\r\n</div>', 1),
(13, 1, 13, 'Otorisasi User dan Grup', 1),
(14, 1, 14, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul User Group digunakan untuk mendaftarkan user access dan group access</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data User Group digunakan di modul: User Login, Render Menu</p>\r\n</div>', 1),
(15, 1, 15, 'Otorisasi Group dan Menu', 1),
(16, 1, 16, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Group Menu digunakan untuk mendaftarkan Group Access dan Menu Access</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Group Menu digunakan untuk otorisasi</p>\r\n</div>', 1),
(17, 1, 17, 'Catatan Transaksi', 1),
(18, 1, 18, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Transaction Log digunakan untuk melihat catatan atau <br/>\r\nlog transaksi yang dilakukan oleh user, sekaligus untuk melakukan <br/>\r\npelacakan siapa user yang melakukan perubahan terhadap suatu data.\r\n</p>\r\n</div>', 1),
(19, 1, 19, 'Transaksi Terkunci', 1),
(20, 1, 20, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Transaction Lock digunakan untuk melihat user yang sedang mengedit data</p>\r\n</div>', 1),
(21, 1, 21, 'Sistem Penomoran', 1),
(22, 1, 22, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Specific Number Range Object (SNRO) digunakan untuk menentukan <br/>\r\nno dokumen otomatis. No dokumen dapat disetting berulang per bulan dan <br/>\r\nper tahun, atau salah satu-nya.</p>\r\n<h1 class="h1help">Pasca Penggunaan Modul</h1>\r\n<p class="phelp">SNRO ini digunakan di berbagai modul yang membutuhkan running no, <br/>\r\nantara lain PR, PO, Surat Jalan, dan lain-lain. <br/>\r\nPenentuan SNRO dilakukan di awal implementasi dan sudah memperhitungkan <br/>\r\nrunning no untuk jangka waktu 5 tahun.\r\n</p>\r\n</div>', 1),
(23, 1, 23, 'Isi Penomoran Aktif', 1),
(24, 1, 24, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Detail of Specific Number Range Object (SNRO) digunakan untuk <br/>\r\nmengetahui / mengatur no terakhir yang dipakai oleh suatu modul. </p>\r\n</div>', 1),
(25, 1, 25, 'Alur Dokumen', 1),
(26, 1, 26, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Workflow digunakan untuk mendaftarkan aliran data dari suatu modul <br/>\r\nmisalkan aliran data approval / reject Purchase Order, Purchase Requisition</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Workflow digunakan di modul Workflow Group, Workflow Status</p>\r\n</div>', 1),
(27, 1, 27, 'Hal Utama', 1),
(28, 1, 28, 'Grup Alur Dokumen', 1),
(29, 1, 29, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Workflow Group digunakan untuk mendaftarkan autorisasi group terhadap suatu workflow modul</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Workflow Group digunakan di seluruh modul yang menggunakan proses approval, insert</p>\r\n</div>', 1),
(30, 1, 30, 'Status Alur Dokumen', 1),
(31, 1, 31, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Workflow Status digunakan untuk mendaftarkan status terhadap suatu workflow modul</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Workflow Status digunakan di seluruh modul yang menggunakan proses approval, insert</p>\r\n</div>', 1),
(32, 1, 32, 'Parameter', 1),
(33, 1, 33, '<div id="help">\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Parameter digunakan untuk menentukan nilai yang dibutuhkan modul lain, <br/>\r\nmisalkan usinglog. Modul lain yang menggunakan parameter using log akan <br/>\r\nmenggunakan nilai yang telah ditentukan.</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Parameter digunakan di seluruh modul yang menggunakan sistem parameter</p>\r\n</div>', 1),
(34, 1, 34, 'Bahasa', 1),
(35, 1, 35, '<div id="help"?\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Language digunakan untuk mendaftarkan bahasa.</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Language digunakan di modul Language, Employee Foreign Language.</p>\r\n</div>', 1),
(36, 1, 36, 'Messages', 1),
(37, 1, 37, '<div id="help"?\r\n<h1 class="h1help">Pendahuluan</h1>\r\n<p class="phelp">Modul Messages digunakan untuk mendaftarkan pesan.</p>\r\n<h1 class="h1help">Relasi</h1>\r\n<p class="phelp">Data Messages digunakan di seluruh modul.</p>\r\n</div>', 1);

DROP TABLE IF EXISTS `city`;
CREATE TABLE IF NOT EXISTS `city` (
  `cityid` int(11) NOT NULL AUTO_INCREMENT,
  `provinceid` int(11) NOT NULL,
  `cityname` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`cityid`),
  KEY `fk_city_province` (`provinceid`),
  KEY `ix_city_name` (`cityname`),
  KEY `ix_city` (`provinceid`,`cityname`,`cityid`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=419 ;

INSERT INTO `city` (`cityid`, `provinceid`, `cityname`, `recordstatus`) VALUES
(1, 1, 'BADUNG', 1),
(2, 1, 'BANGLI', 1),
(3, 1, 'BULELENG', 1),
(4, 1, 'DENPASAR', 1),
(5, 1, 'GIANYAR', 1),
(6, 1, 'JEMBRANA', 1),
(7, 1, 'KARANG ASEM', 1),
(8, 1, 'SEMARAPURA', 1),
(9, 1, 'TABANAN', 1),
(10, 2, 'CILEGON', 1),
(11, 2, 'KABUPATEN TANGERANG', 1),
(12, 2, 'LEBAK', 1),
(13, 2, 'PANDEGLANG', 1),
(14, 2, 'SERANG', 1),
(15, 2, 'TANGERANG', 1),
(16, 3, 'BENGKULU SELATAN', 1),
(17, 3, 'BENGKULU UTARA', 1),
(18, 3, 'KAUR', 1),
(19, 3, 'KODYA BENGKULU', 1),
(20, 3, 'REJANG LEBONG', 1),
(21, 3, 'SELUMA', 1),
(22, 4, 'BANTUL', 1),
(23, 4, 'GUNUNGKIDUL', 1),
(24, 4, 'KULONPROGO', 1),
(25, 4, 'SLEMAN', 1),
(26, 4, 'YOGYAKARTA', 1),
(27, 5, 'JAKARTA', 1),
(28, 5, 'JAKARTA BARAT', 1),
(29, 5, 'JAKARTA PUSAT', 1),
(30, 5, 'JAKARTA SELATAN', 1),
(31, 5, 'JAKARTA TIMUR', 1),
(32, 5, 'JAKARTA UTARA', 1),
(33, 6, 'BATANGHARI', 1),
(34, 6, 'BUNGO', 1),
(35, 6, 'JAMBI', 1),
(36, 6, 'KERINCI', 1),
(37, 6, 'MERANGIN', 1),
(38, 6, 'MUARO JAMBI', 1),
(39, 6, 'SAROLANGUN', 1),
(40, 6, 'TANJAB BARAT', 1),
(41, 6, 'TANJAB TIMUR', 1),
(42, 6, 'TEBO', 1),
(43, 7, 'BANDUNG', 1),
(44, 7, 'BEKASI', 1),
(45, 7, 'BOGOR', 1),
(46, 7, 'CIANJUR', 1),
(47, 7, 'CIMAHI', 1),
(48, 7, 'CIREBON', 1),
(49, 7, 'DEPOK', 1),
(50, 7, 'GARUT', 1),
(51, 7, 'INDRAMAYU', 1),
(52, 7, 'JAWA BARAT', 1),
(53, 7, 'KAB. SUKABUMI', 1),
(54, 7, 'KABUPATEN CIAMIS', 1),
(55, 7, 'KARAWANG', 1),
(56, 7, 'KOTA BANJAR', 1),
(57, 7, 'KOTA MADYA CIREBON', 1),
(58, 7, 'KOTA SUKABUMI', 1),
(59, 7, 'KOTAMADYA BEKASI', 1),
(60, 7, 'KOTATASIKMALAYA', 1),
(61, 7, 'KUNINGAN', 1),
(62, 7, 'MAJALENGKA', 1),
(63, 7, 'PURWAKARTA', 1),
(64, 7, 'SUBANG', 1),
(65, 7, 'SUMEDANG', 1),
(66, 7, 'TASIKMALAYA', 1),
(67, 8, 'BANJARNEGARA', 1),
(68, 8, 'BANYUMAS', 1),
(69, 8, 'BATANG', 1),
(70, 8, 'BLORA', 1),
(71, 8, 'BOYOLALI', 1),
(72, 8, 'CILACAP', 1),
(73, 8, 'DEMAK', 1),
(74, 8, 'GROBOGAN', 1),
(75, 8, 'JEPARA', 1),
(76, 8, 'KAB. BREBES', 1),
(77, 8, 'KAB. PEKALONGAN', 1),
(78, 8, 'KAB. SEMARANG', 1),
(79, 8, 'KAB. TEGAL', 1),
(80, 8, 'KARANGANYAR', 1),
(81, 8, 'KEBUMEN', 1),
(82, 8, 'KENDAL', 1),
(83, 8, 'KLATEN', 1),
(84, 8, 'KODYA PEKALONGAN', 1),
(85, 8, 'KODYA SEMARANG', 1),
(86, 8, 'KOTA TEGAL', 1),
(87, 8, 'KOTAMADYA MAGELANG', 1),
(88, 8, 'KUDUS', 1),
(89, 8, 'MAGELANG', 1),
(90, 8, 'PATI', 1),
(91, 8, 'PEMALANG', 1),
(92, 8, 'PURBALINGGA', 1),
(93, 8, 'PURWODADI', 1),
(94, 8, 'PURWOKERTO', 1),
(95, 8, 'PURWOREJO', 1),
(96, 8, 'REMBANG', 1),
(97, 8, 'SALATIGA', 1),
(98, 8, 'SOLO', 1),
(99, 8, 'SRAGEN', 1),
(100, 8, 'SUKOHARJO', 1),
(101, 8, 'SURAKARTA', 1),
(102, 8, 'TEMANGGUNG', 1),
(103, 8, 'WONOGIRI', 1),
(104, 8, 'WONOSOBO', 1),
(105, 9, 'BANGKALAN', 1),
(106, 9, 'BANYUWANGI', 1),
(107, 9, 'BLITAR', 1),
(108, 9, 'BOJONEGORO', 1),
(109, 9, 'BONDOWOSO', 1),
(110, 9, 'GRESIK', 1),
(111, 9, 'JEMBER', 1),
(112, 9, 'JOMBANG', 1),
(113, 9, 'KAB. KEDIRI', 1),
(114, 9, 'KAB.MOJOKERTO', 1),
(115, 9, 'KAB.NGANJUK', 1),
(116, 9, 'KABUPATEN MALANG', 1),
(117, 9, 'KODYA MOJOKERTO', 1),
(118, 9, 'KODYA PASURUAN', 1),
(119, 9, 'KOTA BATU', 1),
(120, 9, 'KOTA BLITAR', 1),
(121, 9, 'KOTA KEDIRI', 1),
(122, 9, 'KOTA PROBOLINGGO', 1),
(123, 9, 'KOTAMADYA MALANG', 1),
(124, 9, 'LAMONGAN', 1),
(125, 9, 'LUMAJANG', 1),
(126, 9, 'MADIUN', 1),
(127, 9, 'MAGETAN', 1),
(128, 9, 'NGAWI', 1),
(129, 9, 'PACITAN', 1),
(130, 9, 'PAMEKASAN', 1),
(131, 9, 'PASURUAN', 1),
(132, 9, 'PONOROGO', 1),
(133, 9, 'PROBOLINGGO', 1),
(134, 9, 'SAMPANG', 1),
(135, 9, 'SIDOARJO', 1),
(136, 9, 'SITUBONDO', 1),
(137, 9, 'SUMENEP', 1),
(138, 9, 'SURABAYA', 1),
(139, 9, 'TRENGGALEK', 1),
(140, 9, 'TUBAN', 1),
(141, 9, 'TULUNGAGUNG', 1),
(142, 10, 'BENGKAYANG', 1),
(143, 10, 'KAPUAS HULU', 1),
(144, 10, 'KETAPANG', 1),
(145, 10, 'KOTA PONTIANAK', 1),
(146, 10, 'KOTA SINGKAWANG', 1),
(147, 10, 'LANDAK', 1),
(148, 10, 'PONTIANAK', 1),
(149, 10, 'SAMBAS', 1),
(150, 10, 'SANGGAU', 1),
(151, 10, 'SINTANG', 1),
(152, 11, 'BALANGAN                 ', 1),
(153, 11, 'BANJAR                   ', 1),
(154, 11, 'BANJARBARU               ', 1),
(155, 11, 'BANJARMASIN', 1),
(156, 11, 'BARITO KUALA', 1),
(157, 11, 'HULU SUNGAI SELATAN      ', 1),
(158, 11, 'HULU SUNGAI TENGAH       ', 1),
(159, 11, 'HULU SUNGAI UTARA        ', 1),
(160, 11, 'KOTA BARU                ', 1),
(161, 11, 'TABALONG                 ', 1),
(162, 11, 'TANAH BUMBU              ', 1),
(163, 11, 'TANAH LAUT', 1),
(164, 11, 'TAPIN                    ', 1),
(165, 12, 'BARITO SELATAN', 1),
(166, 12, 'BARITO TIMUR', 1),
(167, 12, 'BARITO UTARA', 1),
(168, 12, 'GUNUNG MAS', 1),
(169, 12, 'KAPUAS', 1),
(170, 12, 'KOTA WARINGIN BARAT', 1),
(171, 12, 'KOTA WARINGIN TIMUR', 1),
(172, 12, 'LAMANDAU', 1),
(173, 12, 'MURUNG RAYA', 1),
(174, 12, 'PALANGKA RAYA', 1),
(175, 12, 'PULANG PISAU', 1),
(176, 12, 'SUKAMARA', 1),
(177, 13, 'BALIKPAPAN', 1),
(178, 13, 'BERAU', 1),
(179, 13, 'BONTANG', 1),
(180, 13, 'BULUNGAN', 1),
(181, 13, 'KOTAMADYA TARAKAN', 1),
(182, 13, 'KUTAI BARAT', 1),
(183, 13, 'KUTAI KERTANEGARA', 1),
(184, 13, 'KUTAI TIMUR', 1),
(185, 13, 'MALINAU', 1),
(186, 13, 'NUNUKAN', 1),
(187, 13, 'PASIR', 1),
(188, 13, 'PENAJAM PASER UTARA', 1),
(189, 13, 'SAMARINDA', 1),
(190, 13, 'Sangatta', 1),
(191, 14, 'BANGKA', 1),
(192, 14, 'BANGKA BARAT', 1),
(193, 14, 'BANGKA SELATAN', 1),
(194, 14, 'BANGKA TENGAH', 1),
(195, 14, 'BELITUNG BARAT', 1),
(196, 14, 'BELITUNG TIMUR', 1),
(197, 14, 'PANGKAL PINANG', 1),
(198, 14, 'Sungai LIat', 1),
(199, 15, 'BATAM', 1),
(200, 15, 'KARIMUN', 1),
(201, 15, 'KEPULAUAN RIAU', 1),
(202, 15, 'NATUNA', 1),
(203, 15, 'TANJUNG PINANG', 1),
(204, 16, '', 1),
(205, 16, 'BANDAR LAMPUNG', 1),
(206, 16, 'KOTA METRO', 1),
(207, 16, 'LAMPUNG BARAT', 1),
(208, 16, 'LAMPUNG SELATAN', 1),
(209, 16, 'LAMPUNG TENGAH', 1),
(210, 16, 'LAMPUNG TIMUR', 1),
(211, 16, 'LAMPUNG UTARA', 1),
(212, 16, 'TANGGAMUS', 1),
(213, 16, 'TULANG BAWANG', 1),
(214, 16, 'WAY KANAN', 1),
(215, 17, 'BURU', 1),
(216, 17, 'KEPULAUAN ARU', 1),
(217, 17, 'KOTA AMBON', 1),
(218, 17, 'MALUKU', 1),
(219, 17, 'MALUKU TENGAH', 1),
(220, 17, 'MALUKU TENGGARA', 1),
(221, 17, 'MALUKU TENGGARA BARAT', 1),
(222, 17, 'MALUKUUTARA', 1),
(223, 17, 'SERAM BAGIAN BARAT', 1),
(224, 17, 'SERAM BAGIAN TIMUR', 1),
(225, 18, 'KAB.HALMAHERA TENGAH', 1),
(226, 18, 'KAB.MALUKU UTARA', 1),
(227, 18, 'KOTA MADYA TERNATE', 1),
(228, 19, '', 1),
(229, 19, 'ACEH BARAT', 1),
(230, 19, 'ACEH BARAT DAYA', 1),
(231, 19, 'ACEH BESAR', 1),
(232, 19, 'ACEH JAYA', 1),
(233, 19, 'ACEH SELATAN', 1),
(234, 19, 'ACEH SINGKIL', 1),
(235, 19, 'ACEH TAMIANG', 1),
(236, 19, 'ACEH TENGAH', 1),
(237, 19, 'ACEH TENGGARA', 1),
(238, 19, 'ACEH TIMUR', 1),
(239, 19, 'ACEH UTARA', 1),
(240, 19, 'BANDA ACEH', 1),
(241, 19, 'BENER MERIAH', 1),
(242, 19, 'BIREUEN', 1),
(243, 19, 'GAYO LUES', 1),
(244, 19, 'KOTA LANGSA', 1),
(245, 19, 'KOTA LHOKSEUMAWE', 1),
(246, 19, 'NAGAN RAYA', 1),
(247, 19, 'PIDIE', 1),
(248, 19, 'SABANG', 1),
(249, 19, 'SIMEULUE', 1),
(250, 20, 'BIMA', 1),
(251, 20, 'DOMPU', 1),
(252, 20, 'KODYA MATARAM', 1),
(253, 20, 'KOTA BIMA', 1),
(254, 20, 'LOMBOK BARAT', 1),
(255, 20, 'LOMBOK TENGAH', 1),
(256, 20, 'LOMBOK TIMUR', 1),
(257, 20, 'SUMBAWA', 1),
(258, 21, 'ALOR', 1),
(259, 21, 'BELU', 1),
(260, 21, 'ENDE', 1),
(261, 21, 'FLORES TIMUR', 1),
(262, 21, 'KOTA KUPANG', 1),
(263, 21, 'KUPANG', 1),
(264, 21, 'LEMBATA', 1),
(265, 21, 'MANGGARAI', 1),
(266, 21, 'MANGGARAI BARAT', 1),
(267, 21, 'NGADA', 1),
(268, 21, 'ROTE NDAO', 1),
(269, 21, 'SIKKA', 1),
(270, 21, 'SUMBA BARAT', 1),
(271, 21, 'SUMBA TIMUR', 1),
(272, 21, 'TIMOR TENGAH SELATAN', 1),
(273, 21, 'TIMOR TENGAH UTARA', 1),
(274, 22, 'ASMAT', 1),
(275, 22, 'BIAK NUMFOR', 1),
(276, 22, 'BOVEN DIGOEL', 1),
(277, 22, 'FAK-FAK', 1),
(278, 22, 'JAYAPURA', 1),
(279, 22, 'JAYAWIJAYA', 1),
(280, 22, 'KAB. SORONG', 1),
(281, 22, 'KAIMANA', 1),
(282, 22, 'KEEROM', 1),
(283, 22, 'KOTA SORONG', 1),
(284, 22, 'MANOKWARI', 1),
(285, 22, 'MERAUKE', 1),
(286, 22, 'MIMIKA', 1),
(287, 22, 'NABIRE', 1),
(288, 22, 'PANIAI', 1),
(289, 22, 'PEGUNUNGAN BINTANG', 1),
(290, 22, 'PUNCAK JAYA', 1),
(291, 22, 'SARMI', 1),
(292, 22, 'SORONG SELATAN', 1),
(293, 22, 'TELUK BINTUNI', 1),
(294, 22, 'TELUK WANDAMEN', 1),
(295, 22, 'TOLIKARA', 1),
(296, 22, 'WAROPEN', 1),
(297, 22, 'YAPEN WAROPEN', 1),
(298, 23, 'INDRAGIRI HILIR', 1),
(299, 23, 'INDRAGIRI HULU', 1),
(300, 23, 'KAB.BENGKALIS', 1),
(301, 23, 'KAB.ROKAN HILIR', 1),
(302, 23, 'KAB.SIAK', 1),
(303, 23, 'KAMPAR', 1),
(304, 23, 'KODYA DUMAI', 1),
(305, 23, 'KOTA PEKANBARU', 1),
(306, 23, 'KUANTAN SINGINGI', 1),
(307, 23, 'PELALAWAN', 1),
(308, 23, 'ROKAN HULU', 1),
(309, 24, 'BANTAENG', 1),
(310, 24, 'BARRU', 1),
(311, 24, 'BONE', 1),
(312, 24, 'BULUKUMBA', 1),
(313, 24, 'ENREKANG', 1),
(314, 24, 'GOWA', 1),
(315, 24, 'JENEPONTO', 1),
(316, 24, 'KOTA MAKASSAR', 1),
(317, 24, 'LUWU', 1),
(318, 24, 'LUWU TIMUR', 1),
(319, 24, 'LUWU UTARA', 1),
(320, 24, 'MAJENE', 1),
(321, 24, 'Makasar', 1),
(322, 24, 'MAMASA', 1),
(323, 24, 'MAMUJU', 1),
(324, 24, 'MAROS', 1),
(325, 24, 'PALOPO', 1),
(326, 24, 'PANGKAJENE KEPULAUAN', 1),
(327, 24, 'PAREPARE', 1),
(328, 24, 'PINRANG', 1),
(329, 24, 'POLEWALI', 1),
(330, 24, 'SELAYAR', 1),
(331, 24, 'SIDENRENG RAPPANG', 1),
(332, 24, 'SINJAI', 1),
(333, 24, 'SOPPENG', 1),
(334, 24, 'TAKALAR', 1),
(335, 24, 'TANA TORAJA', 1),
(336, 24, 'Ujung Pandang', 1),
(337, 24, 'Ujungpandang', 1),
(338, 24, 'WAJO', 1),
(339, 25, 'BANGGAI', 1),
(340, 25, 'BANGGAI KEPULAUAN', 1),
(341, 25, 'BUOL', 1),
(342, 25, 'KAB.PARIGI MOUTONG', 1),
(343, 25, 'MOROWALI', 1),
(344, 25, 'PALU', 1),
(345, 25, 'POSO', 1),
(346, 25, 'TOJO UNA-UNA', 1),
(347, 25, 'TOLITOLI', 1),
(348, 26, 'BOMBANA', 1),
(349, 26, 'KAB. BUTON', 1),
(350, 26, 'KAB. KOLAKA', 1),
(351, 26, 'KAB. KONAWE', 1),
(352, 26, 'KAB. MUNA', 1),
(353, 26, 'KOLAKA UTARA', 1),
(354, 26, 'KONAWE SELATAN', 1),
(355, 26, 'KOTA BAU-BAU', 1),
(356, 26, 'KOTA KENDARI', 1),
(357, 26, 'WAKATOBI', 1),
(358, 27, 'BITUNG', 1),
(359, 27, 'BOLAANG MENGONDOW', 1),
(360, 27, 'MANADO', 1),
(361, 27, 'MINAHASA', 1),
(362, 27, 'SANGIHE', 1),
(363, 27, 'TALAUD', 1),
(364, 28, 'AGAM', 1),
(365, 28, 'BUKITTINGGI', 1),
(366, 28, 'KAB.KEP. MENTAWAI', 1),
(367, 28, 'KAB.SOLOK', 1),
(368, 28, 'LIMAPULUH KOTA', 1),
(369, 28, 'NEGERI LAMA', 1),
(370, 28, 'PADANG', 1),
(371, 28, 'PADANG PANJANG', 1),
(372, 28, 'PADANG PARIAMAN', 1),
(373, 28, 'PANTI', 1),
(374, 28, 'PASAMAN', 1),
(375, 28, 'PASAMAN BARAT', 1),
(376, 28, 'PAYAKUMBUH', 1),
(377, 28, 'PESISIR SELATAN', 1),
(378, 28, 'SAWAH LUNTO', 1),
(379, 28, 'SOLOK', 1),
(380, 28, 'SUMBER AGUNG', 1),
(381, 28, 'SWL/SIJUNJUNG', 1),
(382, 28, 'TANAH DATAR', 1),
(383, 29, 'BANYUASIN', 1),
(384, 29, 'INDERAPURA', 1),
(385, 29, 'LAHAT', 1),
(386, 29, 'LUBUK LINGGAU', 1),
(387, 29, 'MUARA ENIM', 1),
(388, 29, 'MUSI BANYU ASIN', 1),
(389, 29, 'MUSI RAWAS', 1),
(390, 29, 'OGAN KOMERING ILIR', 1),
(391, 29, 'OGAN KOMERING ULU', 1),
(392, 29, 'OGAN KOMERING ULU SELATAN', 1),
(393, 29, 'OGAN KOMERING ULU TIMUR', 1),
(394, 29, 'PAGAR ALAM', 1),
(395, 29, 'PALEMBANG', 1),
(396, 29, 'PRABUMULIH', 1),
(397, 30, 'ASAHAN', 1),
(398, 30, 'BINJAI', 1),
(399, 30, 'DAIRI', 1),
(400, 30, 'DELI SERDANG', 1),
(401, 30, 'HUMBANG HASUNDUTAN', 1),
(402, 30, 'KARO', 1),
(403, 30, 'KOTAMADYA MEDAN', 1),
(404, 30, 'LABUHAN BATU', 1),
(405, 30, 'LANGKAT', 1),
(406, 30, 'MANDAILING NATAL', 1),
(407, 30, 'NIAS', 1),
(408, 30, 'NIAS SELATAN', 1),
(409, 30, 'PADANGSIDIMPUAN', 1),
(410, 30, 'PEMATANG SIANTAR', 1),
(411, 30, 'SIBOLGA', 1),
(412, 30, 'SIMALUNGUN', 1),
(413, 30, 'TANJUNG BALAI', 1),
(414, 30, 'TAPANULI SELATAN', 1),
(415, 30, 'TAPANULI TENGAH', 1),
(416, 30, 'TAPANULI UTARA', 1),
(417, 30, 'TEBING TINGGI', 1),
(418, 30, 'TOBA SAMOSIR', 1);

DROP TABLE IF EXISTS `company`;
CREATE TABLE IF NOT EXISTS `company` (
  `companyid` int(11) NOT NULL AUTO_INCREMENT,
  `companyname` varchar(50) NOT NULL,
  `address` varchar(255) NOT NULL,
  `city` varchar(50) NOT NULL,
  `zipcode` varchar(10) DEFAULT NULL,
  `taxno` varchar(50) DEFAULT NULL,
  `currencyid` int(11) NOT NULL,
  `faxno` varchar(50) DEFAULT NULL,
  `phoneno` varchar(50) DEFAULT NULL,
  `webaddress` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `leftlogofile` varchar(50) DEFAULT NULL,
  `rightlogofile` varchar(50) DEFAULT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`companyid`),
  KEY `ix_company_name` (`companyname`),
  KEY `ix_company_city` (`city`) USING BTREE,
  KEY `ix_company` (`companyname`,`address`,`city`,`zipcode`,`taxno`,`currencyid`,`faxno`,`phoneno`,`webaddress`,`email`,`leftlogofile`,`rightlogofile`,`companyid`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3 ;

INSERT INTO `company` (`companyid`, `companyname`, `address`, `city`, `zipcode`, `taxno`, `currencyid`, `faxno`, `phoneno`, `webaddress`, `email`, `leftlogofile`, `rightlogofile`, `recordstatus`) VALUES
(1, 'CV Prisma Data Abadi', 'Ruko Taman Harapan Baru\r\nJl. Taman Harapan Baru Utara Blok N No 6', 'Bekasi', '17131', '', 40, '', '021-90488878 / 087875097026', 'http://www.prismadataabadi.com', 'admin@prismadataabadi.com', 'logo.jpg', NULL, 1),
(2, 'CV Prisma Tour and Travel', 'Ruko Taman Harapan Baru\r\nJl. Taman Harapan Baru Utara Blok N no 6', 'Bekasi', '17131', '', 40, '', '', '', '', NULL, NULL, 1);

DROP TABLE IF EXISTS `country`;
CREATE TABLE IF NOT EXISTS `country` (
  `countryid` int(11) NOT NULL AUTO_INCREMENT,
  `countrycode` varchar(5) NOT NULL,
  `countryname` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`countryid`),
  KEY `ix_country_code` (`countrycode`),
  KEY `ix_country_name` (`countryname`),
  KEY `ix_country` (`countrycode`,`countryname`,`countryid`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=223 ;

INSERT INTO `country` (`countryid`, `countrycode`, `countryname`, `recordstatus`) VALUES
(1, 'AD', 'ANDORRA', 1),
(2, 'AE', 'UNITED ARAB EMIRATES', 1),
(3, 'AF', 'AFGHANISTAN', 1),
(4, 'AG', 'ANTIGUA AND BARBUDA', 1),
(5, 'AI', 'ANGUILLA', 1),
(6, 'AL', 'ALBANIA', 1),
(7, 'AM', 'ARMENIA', 1),
(8, 'AN', 'NETHERLANDS ANTILLES', 1),
(9, 'AO', 'ANGOLA', 1),
(10, 'AQ', 'ANTARCTICA', 1),
(11, 'AR', 'ARGENTINA', 1),
(12, 'AS', 'AMERICAN SAMOA', 1),
(13, 'AT', 'AUSTRIA', 1),
(14, 'AU', 'AUSTRALIA', 1),
(15, 'AW', 'ARUBA', 1),
(16, 'AZ', 'AZERBAIJAN', 1),
(17, 'BA', 'BOSNIA HERZEGOVINA', 1),
(18, 'BB', 'BARBADOS', 1),
(19, 'BD', 'BANGLADESH', 1),
(20, 'BE', 'BELGIUM', 1),
(21, 'BF', 'BURKINA FASO', 1),
(22, 'BG', 'BULGARIA', 1),
(23, 'BH', 'BAHRAIN', 1),
(24, 'BI', 'BURUNDI', 1),
(25, 'BJ', 'BENIN', 1),
(26, 'BM', 'BERMUDA', 1),
(27, 'BN', 'BRUNEI', 1),
(28, 'BO', 'BOLIVIA', 1),
(29, 'BR', 'BRAZIL', 1),
(30, 'BS', 'BAHAMAS', 1),
(31, 'BT', 'BHUTAN', 1),
(32, 'BV', 'BOUVET ISLAND', 1),
(33, 'BW', 'BOTSWANA', 1),
(34, 'BY', 'BELARUS', 1),
(35, 'BZ', 'BELIZE', 1),
(36, 'CA', 'CANADA', 1),
(37, 'CC', 'COCOS ISLANDS', 1),
(38, 'CD', 'CONGO REPUBLIC', 1),
(39, 'CF', 'CENTRAL AFRICA', 1),
(40, 'CG', 'CONGO', 1),
(41, 'CH', 'SWITZERLAND', 1),
(42, 'CI', 'COTE D''IVOIRE', 1),
(43, 'CK', 'COOK ISLANDS', 1),
(44, 'CL', 'CHILI', 1),
(45, 'CM', 'CAMEROON', 1),
(46, 'CN', 'CHINA', 1),
(47, 'CO', 'COLOMBIA', 1),
(48, 'CR', 'COSTA RICA', 1),
(49, 'CU', 'CUBA', 1),
(50, 'CV', 'CAPE VERDE', 1),
(51, 'CX', 'CHRISTMAS ISLAND', 1),
(52, 'CY', 'CYPRUS', 1),
(53, 'CZ', 'CHECH REPUBLIC', 1),
(54, 'DE', 'GERMAN', 1),
(55, 'DJ', 'DJIBOUTI', 1),
(56, 'DK', 'DENMARK', 1),
(57, 'DM', 'DOMINICA', 1),
(58, 'DO', 'DOMINICAN REPUBLIC', 1),
(59, 'DZ', 'ALGERIA', 1),
(60, 'EC', 'ECUADOR', 1),
(61, 'EE', 'ESTONIA', 1),
(62, 'EG', 'EGYPT', 1),
(63, 'ER', 'ERITREA', 1),
(64, 'ES', 'SPAIN', 1),
(65, 'ET', 'ETHIOPIA', 1),
(66, 'FI', 'FINLANDIA', 1),
(67, 'FJ', 'FIJI ISLANDS', 1),
(68, 'FM', 'MICRONESIA', 1),
(69, 'FO', 'FAROE ISLANDS', 1),
(70, 'FR', 'FRANCE', 1),
(71, 'GA', 'GABON', 1),
(72, 'GD', 'GRENADA', 1),
(73, 'GE', 'GEORGIA', 1),
(74, 'GF', 'FRENCH GUIANA', 1),
(75, 'GH', 'GHANA', 1),
(76, 'GI', 'GIBRALTAR', 1),
(77, 'GL', 'GREENLAND', 1),
(78, 'GM', 'GAMBIA', 1),
(79, 'GN', 'GUINEA', 1),
(80, 'GP', 'GUADELOUPE', 1),
(81, 'GQ', 'EQUATORIAL GUINEA', 1),
(82, 'GR', 'GREECE', 1),
(83, 'GT', 'GUATEMALA', 1),
(84, 'GU', 'GUAM', 1),
(85, 'GW', 'GUINEA-BISSAU', 1),
(86, 'GY', 'GUYANA', 1),
(87, 'HK', 'HONGKONGS.A.R.', 1),
(88, 'HN', 'HONDURAS', 1),
(89, 'HR', 'CROATIA(HRVATSKA)', 1),
(90, 'HT', 'HAITI', 1),
(91, 'HU', 'HUNGARIA', 1),
(92, 'ID', 'INDONESIA', 1),
(93, 'IE', 'IRELAND', 1),
(94, 'IL', 'ISRAEL', 1),
(95, 'IN', 'INDIA', 1),
(96, 'IO', 'BRITISH INDIAN OCEAN', 1),
(97, 'IQ', 'IRAQ', 1),
(98, 'IR', 'IRAN', 1),
(99, 'IS', 'ICELAND', 1),
(100, 'IT', 'ITALIA', 1),
(101, 'JM', 'JAMAICA', 1),
(102, 'JO', 'JORDAN', 1),
(103, 'JP', 'JAPAN', 1),
(104, 'KE', 'KENYA', 1),
(105, 'KG', 'KYRGYZSTAN', 1),
(106, 'KH', 'CAMBODIA', 1),
(107, 'KI', 'KIRIBATI', 1),
(108, 'KM', 'COMOROS', 1),
(109, 'KP', 'NORTH KOREAN', 1),
(110, 'KR', 'SOUTH KOREA', 1),
(111, 'KW', 'KUWAIT', 1),
(112, 'KY', 'CAYMAN ISLANDS', 1),
(113, 'KZ', 'KAZAKHSTAN', 1),
(114, 'LA', 'LAOS', 1),
(115, 'LB', 'LEBANON', 1),
(116, 'LI', 'LIECHTENSTEIN', 1),
(117, 'LK', 'SRILANKA', 1),
(118, 'LR', 'LIBERIA', 1),
(119, 'LS', 'LESOTHO', 1),
(120, 'LT', 'LITHUANIA', 1),
(121, 'LU', 'LUXEMBOURG', 1),
(122, 'LV', 'LATVIA', 1),
(123, 'LY', 'LIBYA', 1),
(124, 'MA', 'MOROCCO', 1),
(125, 'MC', 'MONACO', 1),
(126, 'MD', 'REPUBLIC OF MOLDOVA', 1),
(127, 'MG', 'MADAGASKAR', 1),
(128, 'MH', 'MARSHALL ISLANDS', 1),
(129, 'MK', 'REPUBLIC OF MACEDONIA', 1),
(130, 'ML', 'MALI', 1),
(131, 'MM', 'MYANMAR', 1),
(132, 'MN', 'MONGOLIA', 1),
(133, 'MO', 'MACAUS.A.R.', 1),
(134, 'MQ', 'MARTINIQUE', 1),
(135, 'MR', 'MAURITANIA', 1),
(136, 'MS', 'MONTSERRAT', 1),
(137, 'MT', 'MALTA', 1),
(138, 'MU', 'MAURITIUS', 1),
(139, 'MV', 'MALDIVES', 1),
(140, 'MW', 'MALAWI', 1),
(141, 'MX', 'MEXICO', 1),
(142, 'MY', 'MALAYSIA', 1),
(143, 'MZ', 'MOZAMBIQUE', 1),
(144, 'NA', 'NAMIBIA', 1),
(145, 'NC', 'NEW CALEDONIA', 1),
(146, 'NE', 'NIGER', 1),
(147, 'NF', 'NORFOLK ISLAND', 1),
(148, 'NG', 'NIGERIA', 1),
(149, 'NI', 'NICARAGUA', 1),
(150, 'NL', 'NETHERLAND', 1),
(151, 'NO', 'NORWAY', 1),
(152, 'NP', 'NEPAL', 1),
(153, 'NR', 'NAURU', 1),
(154, 'NU', 'NIUE', 1),
(155, 'NZ', 'NEW ZEALAND', 1),
(156, 'OM', 'OMAN', 1),
(157, 'PA', 'PANAMA', 1),
(158, 'PE', 'PERU', 1),
(159, 'PF', 'FRENCH POLYNESIA', 1),
(160, 'PG', 'PAPUA NEW GUINEA', 1),
(161, 'PH', 'PHILIPINES', 1),
(162, 'PK', 'PAKISTAN', 1),
(163, 'PL', 'POLAND', 1),
(164, 'PN', 'PITCAIRN ISLAND', 1),
(165, 'PR', 'PUERTORICO', 1),
(166, 'PT', 'PORTUGAL', 1),
(167, 'PW', 'PALAU', 1),
(168, 'PY', 'PARAGUAY', 1),
(169, 'QA', 'QATAR', 1),
(170, 'RE', 'REUNION', 1),
(171, 'RO', 'ROMANIA', 1),
(172, 'RU', 'RUSSIA', 1),
(173, 'RW', 'RWANDA', 1),
(174, 'SA', 'SAUDIARABIA', 1),
(175, 'SB', 'SOLOMONISLANDS', 1),
(176, 'SC', 'SEYCHELLES', 1),
(177, 'SD', 'SUDAN', 1),
(178, 'SE', 'SWEDIA', 1),
(179, 'SG', 'SINGAPORE', 1),
(180, 'SH', 'SAINTHELENA', 1),
(181, 'SI', 'SLOVENIA', 1),
(182, 'SK', 'SLOVAKIA', 1),
(183, 'SL', 'SIERRALEONE', 1),
(184, 'SM', 'SANMARINO', 1),
(185, 'SN', 'SENEGAL', 1),
(186, 'SO', 'SOMALIA', 1),
(187, 'SR', 'SURINAME', 1),
(188, 'ST', 'SAOTOMEANDPRINCIPE', 1),
(189, 'SV', 'ELSALVADOR', 1),
(190, 'SY', 'SYRIA', 1),
(191, 'SZ', 'SWAZILAND', 1),
(192, 'TD', 'CHAD', 1),
(193, 'TG', 'TOGO', 1),
(194, 'TH', 'THAILAND', 1),
(195, 'TJ', 'TAJIKISTAN', 1),
(196, 'TK', 'TOKELAU', 1),
(197, 'TM', 'TURKMENISTAN', 1),
(198, 'TN', 'TUNISIA', 1),
(199, 'TO', 'TONGA', 1),
(200, 'TP', 'TIMORTIMUR', 1),
(201, 'TR', 'TURKI', 1),
(202, 'TT', 'TRINIDADANDTOBAGO', 1),
(203, 'TV', 'TUVALU', 1),
(204, 'TW', 'TAIWAN', 1),
(205, 'TZ', 'TANZANIA', 1),
(206, 'UA', 'UKRAINE', 1),
(207, 'UG', 'UGANDA', 1),
(208, 'UK', 'INGGRIS', 1),
(209, 'US', 'UNITED STATES OF AMERICA', 1),
(210, 'UY', 'URUGUAY', 1),
(211, 'UZ', 'UZBEKISTAN', 1),
(212, 'VA', 'VATICANCITY', 1),
(213, 'VE', 'VENEZUELA', 1),
(214, 'VN', 'VIETNAM', 1),
(215, 'VU', 'VANUATU', 1),
(216, 'WS', 'SAMOA', 1),
(217, 'YE', 'YAMAN', 1),
(218, 'YT', 'MAYOTTE', 1),
(219, 'YU', 'YUGOSLAVIA', 1),
(220, 'ZA', 'AFRIKASELATAN', 1),
(221, 'ZM', 'ZAMBIA', 1),
(222, 'ZW', 'ZIMBABWE', 1);

DROP TABLE IF EXISTS `currency`;
CREATE TABLE IF NOT EXISTS `currency` (
  `currencyid` int(11) NOT NULL AUTO_INCREMENT,
  `countryid` int(11) NOT NULL,
  `currencyname` varchar(50) NOT NULL,
  `symbol` varchar(3) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`currencyid`),
  UNIQUE KEY `uq_currency_name` (`currencyname`,`countryid`),
  KEY `ix_currency` (`currencyid`,`countryid`,`currencyname`,`symbol`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=172 ;

INSERT INTO `currency` (`currencyid`, `countryid`, `currencyname`, `symbol`, `recordstatus`) VALUES
(1, 1, 'Andoran peseta', 'ADP', 1),
(2, 2, 'United Arab Emirates Dirham', 'AED', 1),
(3, 3, 'Afghani (Old)', 'AFA', 1),
(4, 3, 'Afghani', 'AFN', 1),
(5, 6, 'Albanian Lek', 'ALL', 1),
(6, 7, 'Armenian Dram', 'AMD', 1),
(7, 9, 'Angolanische Kwanza', 'AOA', 1),
(8, 9, 'Angolan New Kwanza (Old)', 'AON', 1),
(9, 9, 'Angolan Kwanza Reajustado (Old)', 'AOR', 1),
(10, 11, 'Argentine Peso', 'ARS', 1),
(11, 13, 'Austrian Schilling', 'ATS', 1),
(12, 14, 'Australian Dollar', 'AUD', 1),
(13, 15, 'Aruban Guilder', 'AWG', 1),
(14, 16, 'Azerbaijan Manat', 'AZM', 1),
(15, 17, 'Bosnia and Herzegovina Convertible Mark', 'BAM', 1),
(16, 18, 'Barbados Dollar', 'BBD', 1),
(17, 19, 'Bangladesh Taka', 'BDT', 1),
(18, 20, 'Belgian Franc', 'BEF', 1),
(19, 22, 'Bulgarian Lev', 'BGN', 1),
(20, 23, 'Bahrain Dinar', 'BHD', 1),
(21, 24, 'Burundi Franc', 'BIF', 1),
(22, 26, 'Bermudan Dollar', 'BMD', 1),
(23, 27, 'Brunei Dollar', 'BND', 1),
(24, 28, 'Boliviano', 'BOB', 1),
(25, 12, 'American Samoa', 'USD', 1),
(26, 21, 'Communaute Financiere Africaine franc CFA Franc', 'XOF', 1),
(27, 25, 'Communaute Financiere Africaine franc', 'XOF', 1),
(28, 29, 'Real', 'BRL', 1),
(29, 4, 'East Caribbean dollar', 'XCD', 1),
(31, 30, 'Bahamian dollar', 'BSD', 1),
(32, 31, 'ngultrum', 'BTN', 1),
(33, 31, 'Indian Rupee', 'INR', 1),
(34, 33, 'Pula', 'BWP', 1),
(35, 34, 'Belarusian ruble', 'BYB', 1),
(36, 35, 'Belizean dollar', 'BZD', 1),
(37, 36, 'Canadian Dollar', 'CAD', 1),
(38, 37, 'Australian dollar', 'AUD', 1),
(39, 38, 'Congolese franc', 'CDF', 1),
(40, 92, 'Rupiah', 'Rp.', 1),
(41, 209, 'United States Dollar', 'USD', 1),
(42, 208, 'Poundsterling', 'GBP', 1),
(43, 179, 'Singapore Dollar', 'SGD', 1),
(44, 39, 'Communaute Financiere Africaine franc', 'XAF', 1),
(45, 40, 'Communaute Financiere Africaine franc', 'XAF', 1),
(46, 41, 'Swiss franc', 'CHF', 1),
(47, 42, 'Communaute Financiere Africaine franc', 'XAF', 1),
(48, 43, 'New Zealand dollar', 'NZD', 1),
(49, 44, 'Chilean peso', 'CLP', 1),
(50, 45, 'Communaute Financiere Africaine franc', 'XAF', 1),
(51, 46, 'Yuan', 'CNY', 1),
(52, 47, 'Colombian peso', 'COP', 1),
(53, 48, 'Costa Rican colon', 'CRC', 1),
(54, 49, 'Cuban peso', 'CUP', 1),
(55, 50, 'Cape Verdean escudo', 'CVE', 1),
(56, 51, 'Australian dollar', 'AUD', 1),
(57, 52, 'Cypriot pound', 'CYP', 1),
(58, 52, 'Turkish lira', 'TRL', 1),
(59, 53, 'Czech Koruna', 'CZK', 1),
(60, 54, 'Euro', 'EUR', 1),
(61, 55, 'Djiboutian franc', 'DJF', 1),
(62, 56, 'Danish krone', 'DKK', 1),
(63, 57, 'East Caribbean dollar', 'XCD', 1),
(64, 58, 'Dominican peso', 'DOP', 1),
(65, 59, 'Algerian dinar', 'DZD', 1),
(66, 60, 'United States Dollar', 'USD', 1),
(67, 61, 'Euro', 'EUR', 1),
(68, 62, 'Egyptian pound', 'EGP', 1),
(69, 63, 'Nakfa', 'ERN', 1),
(70, 64, 'Euro', 'EUR', 1),
(71, 65, 'Birr', 'ETB', 1),
(72, 66, 'Euro', 'EUR', 1),
(73, 67, 'Fijian dollar', 'FJD', 1),
(74, 68, 'United States Dollar', 'USD', 1),
(75, 70, 'Euro', 'EUR', 1),
(76, 71, 'Communaute Financiere Africaine franc', 'XAF', 1),
(77, 72, 'East Caribbean dollar', 'XCD', 1),
(78, 73, 'Lari', 'GEL', 1),
(79, 74, 'Euro', 'EUR', 1),
(80, 75, 'Cedi', 'GHS', 1),
(81, 76, 'Gibraltar pound', 'GIP', 1),
(82, 77, 'Danish krone', 'DKK', 1),
(83, 78, 'Dalasi', 'GMD', 1),
(84, 79, 'Guniean Franc', 'GNF', 1),
(85, 80, 'Euro', 'EUR', 1),
(86, 81, 'Communaute Financiere Africaine franc', 'XAF', 1),
(87, 82, 'Euro', 'EUR', 1),
(88, 83, 'quetzal', 'GTQ', 1),
(89, 83, 'United States Dollar', 'USD', 1),
(90, 84, 'United States Dollar', 'USD', 1),
(91, 85, 'Communaute Financiere Africaine franc', 'XOF', 1),
(92, 86, 'Guyanese dollar', 'GYD', 1),
(93, 87, 'Yuan', 'CNY', 1),
(94, 88, 'Lempira', 'NHL', 1),
(95, 89, 'Kuna', 'HRK', 1),
(96, 90, 'Gourde', 'HTG', 1),
(97, 91, 'Forint', 'HUF', 1),
(98, 93, 'Euro', 'EUR', 1),
(99, 94, 'new Israeli shekel', 'ILS', 1),
(100, 95, 'Indian rupee', 'INR', 1),
(101, 96, 'British Poundsterling', 'GBP', 1),
(102, 96, 'United States Dollar', 'USD', 1),
(103, 97, 'Iraqi dinar', 'IQD', 1),
(104, 98, 'Iranian rial', 'IRR', 1),
(105, 99, 'Icelandic krona', 'ISK', 1),
(106, 100, 'Euro', 'EUR', 1),
(107, 101, 'Jamaican dollar', 'JMD', 1),
(108, 102, 'Jordanian dinar', 'JOD', 1),
(109, 103, 'Yen', 'JPY', 1),
(110, 104, 'Kenyan shilling', 'KES', 1),
(111, 105, 'Kyrgyzstani som', 'KGS', 1),
(112, 106, 'Riel', 'KHR', 1),
(113, 107, 'Australian dollar', 'AUD', 1),
(114, 108, 'Comoran franc', 'KMF', 1),
(115, 109, 'North Korean won', 'KPW', 1),
(116, 110, 'South Korean won', 'KRW', 1),
(117, 111, 'Kuwaiti dinar', 'KWD', 1),
(118, 112, 'Caymanian dollar', 'KYD', 1),
(119, 113, 'Tenge', 'KZT', 1),
(120, 114, 'Kip', 'LAK', 1),
(121, 115, 'Lebanese pound', 'LBP', 1),
(122, 116, 'Swiss franc', 'CHF', 1),
(123, 117, 'Sri Lankan rupee', 'LKR', 1),
(124, 118, 'Liberian dollar', 'LRD', 1),
(125, 119, 'Loti', 'LSL', 1),
(126, 120, 'South African Rand', 'ZAR', 1),
(127, 121, 'Litas', 'LTL', 1),
(128, 122, 'Euro', 'EUR', 1),
(129, 123, 'Libyan dinar', 'LYD', 1),
(130, 124, 'Moroccan dirham', 'MAD', 1),
(131, 125, 'Euro', 'EUR', 1),
(132, 126, 'Moldovan Leu', 'MDL', 1),
(133, 127, 'Ariary', 'MGA', 1),
(134, 128, 'United States Dollar', 'USD', 1),
(135, 129, 'Macedonian denar', 'MKD', 1),
(136, 130, 'Communaute Financiere Africaine franc', 'XOF', 1),
(137, 132, 'togrog/tugrik', 'MNT', 1),
(138, 133, 'Yuan', 'CNY', 1),
(139, 134, 'Euro', 'EUR', 1),
(140, 135, 'ouguiya', 'MRO', 1),
(141, 136, 'East Caribbean dollar', 'XCD', 1),
(142, 137, 'Euro', 'EUR', 1),
(143, 138, 'Mauritian rupee', 'MUR', 1),
(144, 139, 'rufiyaa', 'MVR', 1),
(145, 140, 'Malawian kwacha', 'MWK', 1),
(146, 141, 'Mexican peso', 'MXN', 1),
(147, 142, 'Ringgit', 'MYR', 1),
(148, 143, 'Metical', 'MZM', 1),
(149, 144, 'Namibian dollar', 'NAD', 1),
(150, 144, 'South African Rand', 'ZAR', 1),
(151, 145, 'Comptoirs Francais du Pacifique franc', 'XPF', 1),
(152, 146, 'Communaute Financiere Africaine franc', 'XOF', 1),
(153, 147, 'Australian dollar', 'AUD', 1),
(154, 148, 'naira', 'NGN', 1),
(155, 149, 'gold cordoba', 'NIO', 1),
(156, 150, 'Euro', 'EUR', 1),
(157, 151, 'Norwegian krone', 'NOK', 1),
(158, 152, 'Nepalese rupee', 'NPR', 1),
(159, 153, 'Austrailian Dollar', 'AUD', 1),
(160, 154, 'New Zealand dollar', 'NZD', 1),
(161, 155, 'New Zealand dollar', 'NZD', 1),
(162, 156, 'Omani rial', 'OMR', 1),
(163, 157, 'Panama Balboa', 'PAB', 1),
(164, 157, 'United States Dollar', 'USD', 1),
(165, 158, 'nuevo sol', 'PEN', 1),
(166, 159, 'Comptoirs Francais du Pacifique franc', 'XPF', 1),
(167, 160, 'kina', 'PGK', 1),
(168, 161, 'Philippine peso', 'PHP', 1),
(169, 162, 'Pakistani rupee', 'PKR', 1),
(170, 163, 'zloty', 'PLN', 1),
(171, 164, 'New Zealand dollar', 'NZD', 1);

DROP TABLE IF EXISTS `docprint`;
CREATE TABLE IF NOT EXISTS `docprint` (
  `doclistid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `docid` int(10) unsigned NOT NULL,
  `docprint` int(10) unsigned NOT NULL,
  `printdate` datetime NOT NULL,
  `printby` varchar(50) NOT NULL,
  PRIMARY KEY (`doclistid`),
  KEY `ix_docprint` (`docid`,`docprint`,`printdate`,`printby`,`doclistid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `groupaccess`;
CREATE TABLE IF NOT EXISTS `groupaccess` (
  `groupaccessid` int(11) NOT NULL AUTO_INCREMENT,
  `groupname` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`groupaccessid`),
  UNIQUE KEY `uq_groupname` (`groupname`) USING BTREE,
  KEY `ix_group` (`groupaccessid`,`groupname`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

INSERT INTO `groupaccess` (`groupaccessid`, `groupname`, `recordstatus`) VALUES
(1, 'administrator', 1);

DROP TABLE IF EXISTS `groupmenu`;
CREATE TABLE IF NOT EXISTS `groupmenu` (
  `groupmenuid` int(11) NOT NULL AUTO_INCREMENT,
  `groupaccessid` int(11) NOT NULL,
  `menuaccessid` int(11) NOT NULL,
  `isread` tinyint(4) NOT NULL DEFAULT '0',
  `iswrite` tinyint(4) NOT NULL DEFAULT '0',
  `ispost` tinyint(4) NOT NULL DEFAULT '0',
  `isreject` tinyint(4) NOT NULL DEFAULT '0',
  `isupload` tinyint(4) NOT NULL DEFAULT '0',
  `isdownload` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`groupmenuid`),
  UNIQUE KEY `uq_groupmenu_gm` (`groupaccessid`,`menuaccessid`),
  KEY `FK_groupmenu_menu` (`menuaccessid`),
  KEY `ix_groupmenu` (`groupmenuid`,`groupaccessid`,`menuaccessid`,`isread`,`iswrite`,`ispost`,`isreject`,`isupload`,`isdownload`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=21 ;

INSERT INTO `groupmenu` (`groupmenuid`, `groupaccessid`, `menuaccessid`, `isread`, `iswrite`, `ispost`, `isreject`, `isupload`, `isdownload`) VALUES
(1, 1, 1, 1, 1, 1, 1, 1, 1),
(2, 1, 2, 1, 1, 1, 1, 1, 1),
(3, 1, 3, 1, 1, 1, 1, 1, 1),
(4, 1, 4, 1, 1, 1, 1, 1, 1),
(5, 1, 5, 1, 1, 1, 1, 1, 1),
(6, 1, 6, 1, 1, 1, 1, 1, 1),
(7, 1, 7, 1, 1, 1, 1, 1, 1),
(8, 1, 8, 1, 1, 1, 1, 1, 1),
(9, 1, 9, 1, 1, 1, 1, 1, 1),
(10, 1, 10, 1, 1, 1, 1, 1, 1),
(11, 1, 11, 1, 1, 1, 1, 1, 1),
(12, 1, 12, 1, 1, 1, 1, 1, 1),
(13, 1, 13, 1, 1, 1, 1, 1, 1),
(14, 1, 14, 1, 1, 1, 1, 1, 1),
(15, 1, 15, 1, 1, 1, 1, 1, 1),
(16, 1, 16, 1, 1, 1, 1, 1, 1),
(17, 1, 17, 1, 1, 1, 1, 1, 1),
(18, 1, 18, 1, 1, 1, 1, 1, 1),
(19, 1, 19, 1, 1, 1, 1, 1, 1),
(20, 1, 20, 1, 1, 1, 1, 1, 1);

DROP TABLE IF EXISTS `groupmenuauth`;
CREATE TABLE IF NOT EXISTS `groupmenuauth` (
  `groupmenuauthid` int(11) NOT NULL AUTO_INCREMENT,
  `groupaccessid` int(11) NOT NULL,
  `menuauthid` int(11) NOT NULL,
  `menuvalue` text NOT NULL,
  PRIMARY KEY (`groupmenuauthid`),
  UNIQUE KEY `uq_gma_gm` (`groupaccessid`,`menuauthid`),
  KEY `fk_groupmenuauth_1` (`groupaccessid`),
  KEY `fk_groupmenuauth_2` (`menuauthid`),
  KEY `ix_gma` (`groupmenuauthid`,`groupaccessid`,`menuauthid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `language`;
CREATE TABLE IF NOT EXISTS `language` (
  `languageid` int(11) NOT NULL AUTO_INCREMENT,
  `languagename` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`languageid`),
  UNIQUE KEY `uq_language` (`languagename`),
  KEY `ix_language` (`languageid`,`languagename`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3 ;

INSERT INTO `language` (`languageid`, `languagename`, `recordstatus`) VALUES
(1, 'INDONESIA', 1),
(2, 'ENGLISH', 1);

DROP TABLE IF EXISTS `menuaccess`;
CREATE TABLE IF NOT EXISTS `menuaccess` (
  `menuaccessid` int(11) NOT NULL AUTO_INCREMENT,
  `menucode` varchar(10) NOT NULL,
  `menuname` varchar(50) NOT NULL,
  `description` varchar(50) NOT NULL,
  `menuurl` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  `iconfile` varchar(50) NOT NULL,
  `isparent` tinyint(4) NOT NULL DEFAULT '1',
  `parentid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`menuaccessid`),
  KEY `ix_menucode` (`menucode`),
  KEY `ix_menuname` (`menuname`),
  KEY `ix_description` (`description`),
  KEY `ix_menuurl` (`menuurl`),
  KEY `ix_menuaccess` (`menuaccessid`,`menucode`,`menuname`,`description`,`menuurl`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=21 ;

INSERT INTO `menuaccess` (`menuaccessid`, `menucode`, `menuname`, `description`, `menuurl`, `recordstatus`, `iconfile`, `isparent`, `parentid`) VALUES
(1, 'system', 'system', 'System', 'system/index', 1, 'system.png', 1, 0),
(2, 'sco', 'company', 'Company', 'company/index', 1, 'company.png', 0, 1),
(3, 'sua', 'useraccess', 'User Access', 'useraccess/index', 1, 'useraccess.png', 0, 4),
(4, 'objectauth', 'objectauth', 'Object Authentication', 'objectauth/index', 1, '', 1, 0),
(5, 'suma', 'menuaccess', 'Menu Access', 'menuaccess/index', 1, '', 0, 4),
(6, 'sumo', 'menuauth', 'Menu Auth', 'menuauth/index', 1, '', 0, 4),
(7, 'soga', 'groupaccess', 'Group Access', 'groupaccess/index', 1, '', 0, 4),
(8, 'soug', 'usergroup', 'User Group', 'usergroup/index', 1, '', 0, 4),
(9, 'sogm', 'groupmenu', 'Group Menu', 'groupmenu/index', 1, '', 0, 4),
(10, 'stl', 'translog', 'Transaction Log', 'translog/index', 1, '', 0, 1),
(11, 'stlck', 'translock', 'Transaction Lock', 'translock/index', 1, '', 0, 1),
(12, 'ssnro', 'snro', 'Specific Number Range Object', 'snro/index', 1, '', 0, 1),
(13, 'ssnrodet', 'snrodet', 'SNRO Detail', 'snrodet/index', 1, '', 0, 1),
(14, 'swf', 'workflow', 'Workflow', 'workflow/index', 1, '', 0, 1),
(15, 'home', 'home', 'Home', 'site/index', 1, '', 0, 0),
(16, 'swfg', 'wfgroup', 'Workflow Group', 'wfgroup/index', 1, '', 0, 1),
(17, 'swfs', 'wfstatus', 'Workflow Status', 'wfstatus/index', 1, '', 0, 1),
(18, 'sp', 'parameter', 'Parameter', 'parameter/index', 1, '', 0, 1),
(19, 'sla', 'language', 'Language', 'language/index', 1, '', 0, 1),
(20, 'slm', 'messages', 'Messages', 'messages/index', 1, '', 0, 1);

DROP TABLE IF EXISTS `menuauth`;
CREATE TABLE IF NOT EXISTS `menuauth` (
  `menuauthid` int(11) NOT NULL,
  `menuobject` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`menuauthid`),
  UNIQUE KEY `uq_menuobject` (`menuobject`),
  KEY `ix_menuauth` (`menuauthid`,`menuobject`,`recordstatus`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `menuauth` (`menuauthid`, `menuobject`, `recordstatus`) VALUES
(1, 'sloc', 1),
(2, 'useraccess', 1);

DROP TABLE IF EXISTS `messages`;
CREATE TABLE IF NOT EXISTS `messages` (
  `messagesid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `messagename` varchar(50) NOT NULL,
  `description` varchar(150) NOT NULL,
  `recordstatus` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`messagesid`),
  UNIQUE KEY `uq_messages_name` (`messagename`),
  KEY `ix_messages` (`messagesid`,`messagename`,`description`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=38 ;

INSERT INTO `messages` (`messagesid`, `messagename`, `description`, `recordstatus`) VALUES
(1, 'company', 'Company', 1),
(2, 'active', 'Active', 1),
(3, 'notactive', 'Not Active', 1),
(4, 'companyhelp', 'Company Help', 1),
(5, 'useraccess', 'User Access', 1),
(6, 'useraccesshelp', 'User Access Help', 1),
(7, 'menuaccess', 'Menu Access', 1),
(8, 'menuaccesshelp', 'Menu Access Help', 1),
(9, 'menuauth', 'Menu Authentication', 1),
(10, 'menuauthhelp', 'Menu Authentication Help', 1),
(11, 'groupaccess', 'Group Access', 1),
(12, 'groupaccesshelp', 'Group Access Help', 1),
(13, 'usergroup', 'User Group', 1),
(14, 'usergrouphelp', 'User Group Help', 1),
(15, 'groupmenu', 'Group Menu', 1),
(16, 'groupmenuhelp', 'Group Menu Help', 1),
(17, 'translog', 'Transaction Log', 1),
(18, 'transloghelp', 'Transaction Log Help', 1),
(19, 'translock', 'Transaction Lock', 1),
(20, 'translockhelp', 'Transaction Lock Help', 1),
(21, 'snro', 'Specific Number Range Object', 1),
(22, 'snrohelp', 'SNRO Help', 1),
(23, 'snrodet', 'SNRO Detail', 1),
(24, 'snrodethelp', 'SNRO Detail Help', 1),
(25, 'workflow', 'Workflow', 1),
(26, 'workflowhelp', 'Workflow Help', 1),
(27, 'home', 'Home', 1),
(28, 'wfgroup', 'Workflow Group', 1),
(29, 'wfgrouphelp', 'Workflow Group Help', 1),
(30, 'wfstatus', 'Workflow Status', 1),
(31, 'wfstatushelp', 'Workflow Status Help', 1),
(32, 'parameter', 'Parameter', 1),
(33, 'parameterhelp', 'Parameter Help', 1),
(34, 'language', 'Language', 1),
(35, 'languagehelp', 'Language Help', 1),
(36, 'messages', 'Messages', 1),
(37, 'messageshelp', 'Messages Help', 1);

DROP TABLE IF EXISTS `parameter`;
CREATE TABLE IF NOT EXISTS `parameter` (
  `parameterid` int(11) NOT NULL AUTO_INCREMENT,
  `paramname` varchar(30) NOT NULL,
  `paramvalue` varchar(50) NOT NULL,
  `description` varchar(50) NOT NULL,
  `recordstatus` int(11) NOT NULL,
  PRIMARY KEY (`parameterid`),
  UNIQUE KEY `uq_param_name` (`paramname`),
  KEY `ix_parameter` (`parameterid`,`paramname`,`paramvalue`,`description`,`recordstatus`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=40 ;

INSERT INTO `parameter` (`parameterid`, `paramname`, `paramvalue`, `description`, `recordstatus`) VALUES
(1, 'hpnoti0', '02190488878', 'HP Notification No', 1),
(2, 'usingoldnik', '0', 'All EmployeeData using old nik', 1),
(3, 'outofday', '*', 'Tanda untuk tgl lebih dari akhir bulan', 1),
(4, 'usinglog', '1', 'Tanda untuk aktif log (1) / tidak (0)', 1),
(5, 'smtpserver', '172.21.1.7', 'SMTP Server for sending email', 1),
(6, 'smtpport', '25', 'SMTP Port for sending email', 1),
(7, 'fromemail', 'siskalandre@yahoo.com', 'From Email', 1),
(8, 'eventsms', '0', 'Event SMS Notification', 1),
(9, 'eventmail', '0', 'Event Email Notification', 1),
(10, 'transferstockout', '2', 'Transfer Stock menyatakan barang keluar', 1),
(11, 'emailproject', 'siskalandre@yahoo.com,audi_sulistya@yahoo.com', 'Project Email Notification', 1),
(12, 'accountdebetstartmoney', '3', 'Account ketika uang dikeluarkan dari kas', 1),
(13, 'statpettystartmoney', '3', 'Status Petty Cash mengeluarkan uang', 1),
(14, 'msgstartmoney', 'Mulai Kas Bon', 'Note yang ditulis di journal saat memulai kas bon', 1),
(15, 'msgrepmoney', 'Laporan Kas Bon', 'Note yang ditulis di journal saat laporan kas bon', 1),
(16, 'projectfinish', '1', 'Status Project Finish', 1),
(17, 'projectinv', '6', 'Status Project Invoice', 1),
(18, 'projectpaid', '4', 'Status Project Paid', 1),
(19, 'wageovertime', '7', 'ID wage type untuk overtime', 1),
(20, 'freeschedule', '8', 'Hari libur', 1),
(21, 'wagemeal', '3', 'ID wage type untuk meal', 1),
(22, 'wagetransport', '4', 'ID wage type untuk transport', 1),
(23, 'wagegapok', '1', 'ID wage gaji pokok', 1),
(24, 'idbos', '1', 'ID Bos', 1),
(25, 'latestatus', 'DT', 'Status Datang Terlambat', 1),
(26, 'starschedule', '9', 'Tidak ada di kalendar', 1),
(27, 'wagejabatan', '2', 'ID wage type untuk jabatan', 1),
(28, 'wagekhusus', '5', 'ID wage type untuk khusus', 1),
(29, 'wagetunpajak', '23', 'ID wage type untuk tunjangan pajak', 1),
(30, 'wagepotpajak', '24', 'ID wage type untuk potongan pajak', 1),
(31, 'taxcostlimit', '6000000', 'Biaya Jabatan setahun', 1),
(32, 'percenttaxcost', '5', 'Persentase Biaya Jabatan setahun', 1),
(33, 'penalty', '25', 'ID wagetype untuk penalti', 1),
(34, 'tunjanganpajakrutinpp', '23', 'ID wagetype untuk tunjangan pajak', 1),
(35, 'potonganpajakrutinpp', '24', 'ID wagetype untuk potongan pajak', 1),
(36, 'tunjanganpajaknonrutinpp', '29', 'ID wagetype untuk tunjangan pajak non rutin', 1),
(37, 'potonganpajaknonrutinpp', '30', 'ID wagetype untuk potongan pajak non rutin', 1),
(38, 'tunjangapajakrutinpekerja', '31', 'ID wagetype untuk tunjangan pajak pekerja', 1),
(39, 'potonganpajakrutinpekerja', '32', 'ID wagetype untuk potongan pajak pekerja', 1);

DROP TABLE IF EXISTS `province`;
CREATE TABLE IF NOT EXISTS `province` (
  `provinceid` int(11) NOT NULL AUTO_INCREMENT,
  `countryid` int(11) NOT NULL,
  `provincename` varchar(50) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`provinceid`),
  UNIQUE KEY `uq_province_cp` (`countryid`,`provincename`),
  KEY `fk_province_country` (`countryid`),
  KEY `ix_province_name` (`provincename`),
  KEY `ix_province` (`provinceid`,`countryid`,`provincename`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=31 ;

INSERT INTO `province` (`provinceid`, `countryid`, `provincename`, `recordstatus`) VALUES
(1, 92, 'BALI', 1),
(2, 92, 'BANTEN', 1),
(3, 92, 'BENGKULU', 1),
(4, 92, 'D I YOGYAKARTA', 1),
(5, 92, 'DKI JAKARTA', 1),
(6, 92, 'JAMBI', 1),
(7, 92, 'JAWA BARAT', 1),
(8, 92, 'JAWA TENGAH', 1),
(9, 92, 'JAWA TIMUR', 1),
(10, 92, 'KALIMANTAN BARAT', 1),
(11, 92, 'KALIMANTAN SELATAN', 1),
(12, 92, 'KALIMANTAN TENGAH', 1),
(13, 92, 'KALIMANTAN TIMUR', 1),
(14, 92, 'KEP. BANGKA BELITUNG', 1),
(15, 92, 'KEPULAUAN RIAU', 1),
(16, 92, 'LAMPUNG', 1),
(17, 92, 'MALUKU', 1),
(18, 92, 'MALUKU UTARA', 1),
(19, 92, 'N.A.D', 1),
(20, 92, 'NUSA TENGGARA BARAT', 1),
(21, 92, 'NUSA TENGGARA TIMUR', 1),
(22, 92, 'PAPUA', 1),
(23, 92, 'R I A U', 1),
(24, 92, 'SULAWESI SELATAN', 1),
(25, 92, 'SULAWESI TENGAH', 1),
(26, 92, 'SULAWESI TENGGARA', 1),
(27, 92, 'SULAWESI UTARA', 1),
(28, 92, 'SUMATERA BARAT', 1),
(29, 92, 'SUMATERA SELATAN', 1),
(30, 92, 'SUMATERA UTARA', 1);

DROP TABLE IF EXISTS `snro`;
CREATE TABLE IF NOT EXISTS `snro` (
  `snroid` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(50) NOT NULL,
  `formatdoc` varchar(50) NOT NULL,
  `formatno` varchar(10) NOT NULL,
  `repeatby` varchar(30) DEFAULT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`snroid`),
  UNIQUE KEY `uq_snro_desc` (`description`),
  KEY `ix_snro_format` (`description`,`formatdoc`,`formatno`,`repeatby`,`snroid`,`recordstatus`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='Specific Number Range Object' AUTO_INCREMENT=57 ;

INSERT INTO `snro` (`snroid`, `description`, `formatdoc`, `formatno`, `repeatby`, `recordstatus`) VALUES
(25, 'Asset Kantor', '00000/AKNT/MONROM/YYYY', '00000', 'MMYYYY', 1),
(27, 'Asset Kursi', '00000/AKR/MONROM/YYYY', '00000', 'MMYYYY', 1),
(26, 'Asset Meja', '00000/AMJ/MONROM/YYYY', '00000', 'MMYYYY', 1),
(28, 'Asset Mobil', '00000/AMBL/MONROM/YYYY', '00000', 'MMYYYY', 1),
(29, 'Asset Motor', '00000/AMTR/MONROM/YYYY', '00000', 'MMYYYY', 1),
(24, 'Asset Ruangan', '00000/ARUANG/MONROM/YYYY', '00000', 'MMYYYY', 1),
(55, 'Bank In', '0000/BR/MM/YY', '0000', 'MMYY', 1),
(53, 'Bank Out', '0000/BP/MM/YY', '0000', 'MMYY', 1),
(44, 'BAOL No', '0000/SM-OPS/SSO/MMYY', '0000', 'MMYY', 1),
(18, 'Beginning Stock', '00000/BS/MONROM/YYYY', '00000', 'MMYYYY', 1),
(47, 'Cash Bank Deposit', '00000/BKM/MM/YYYY', '00000', 'MMYYYY', 1),
(51, 'Cash Bank In', '0000/CBR/MM/YY', '0000', 'MMYY', 1),
(50, 'Cash Bank Out', '0000/CBP/MM/YY', '0000', 'MMYY', 1),
(46, 'Cash Bank Withdrawal', '00000/BKK/MM/YYYY', '00000', 'MMYYYY', 1),
(54, 'Cash In', '0000/CR/MM/YY', '0000', 'MMYY', 1),
(52, 'Cash Out', '0000/CP/MM/YY', '0000', 'MMYY', 1),
(14, 'Cuti Bencana Alam', '000/004/CBA/MONROM/YYYY', '000', 'MMYYYY', 1),
(36, 'Cuti Besar', '000/004/CB/MONROM/YYYY', '000', 'MMYYYY', 1),
(8, 'Cuti Duka Cita', '000/004/CD/MONROM/YYYY', '000', 'MMYYYY', 1),
(12, 'Cuti Istri Keguguran', '000/004/CIK/MONROM/YYYY', '000', 'MMYYYY', 1),
(11, 'Cuti Istri Melahirkan', '000/004/CIM/MONROM/YYYY', '000', 'MMYYYY', 1),
(10, 'Cuti Keguguran', '000/004/CK/MONROM/YYYY', '000', 'MMYYYY', 1),
(13, 'Cuti Khitan Anak', '000/004/CKA/MONROM/YYYY', '000', 'MMYYYY', 1),
(7, 'Cuti Melahirkan', '000/004/CM/MONROM/YYYY', '000', 'MMYYYY', 1),
(9, 'Cuti Menikah', '000/004/CN/MONROM/YYYY', '000', 'MMYYYY', 1),
(6, 'Cuti Tahunan', '000/004/CT/MONROM/YYYY', '000', 'MMYYYY', 1),
(35, 'Delivery Advice', 'QM/RQ/00000000/YY', '00000000', 'YY', 1),
(23, 'Delivery Order', '00000/DO/MONROM/YYYY', '00000', 'MMYYYY', 1),
(33, 'Employee Overtime', 'EO/MM/YYYY/00000', '00000', 'MMYYYY', 1),
(1, 'Employee Type Harian', '2000000', '000000', '', 1),
(2, 'Employee Type Karyawan', '0000', '0000', '', 1),
(3, 'Employee Type Outsourcing', 'A000', '000', '', 1),
(49, 'Faktur Pajak', '010.000-YY.00000000', '00000000', 'YY', 1),
(32, 'General Journal', 'JU/MM/YYYY/000000000', '000000000', 'YYYY', 1),
(20, 'Goods Issue', '00000/GI/MONROM/YYYY', '00000', 'MMYYYY', 1),
(17, 'Goods Receipt', '00000/GR/MONROM/YYYY', '00000', 'MMYYYY', 1),
(48, 'Invoice Customer', '00000/INV/MM/YYYY', '00000', 'MMYYYY', 1),
(56, 'Journal Adjustment', '0000/JA/MM/YY', '0000', 'MMYY', 1),
(37, 'Kode Barang', 'YYMMMTPMGMGO00000', '00000', 'MTPMGMGOMMYY', 1),
(38, 'Kode Jaringan', 'YYMM000000', '000000', 'MMYY', 1),
(15, 'Permit Exit', '0000/005/PME/MONROM/YYYY', '0000', 'MMYYYY', 1),
(16, 'Permit In', '0000/005/PMI/MONROM/YYYY', '0000', 'MMYYYY', 1),
(31, 'Petty Cash', 'BKK/MM/YYYY/00000', '00000', 'MMYYYY', 1),
(34, 'Project', 'YYCC.PT.PP.MM000', '000', 'CCPTPPMMYY', 1),
(19, 'Purchase Order', 'NWPO/000000/YY', '000000', 'YY', 1),
(21, 'Purchase Order Customer', '00000/POC/MONROM/YYYY', '00000', 'MMYYYY', 1),
(4, 'Purchase Requisition', '00000/PUR01/MONROM/YYYY', '00000', 'MMYYYY', 1),
(22, 'Sales Order', '00000/SO/MONROM/YYYY', '00000', 'MMYYYY', 1),
(40, 'Sales Order Jaringan', 'SO/N/MM/YY/00000', '00000', 'MMYY', 1),
(39, 'Sales Order Vast', 'SO/V/MM/YY/00000', '00000', 'MMYY', 1),
(5, 'Sickness Transaction', '000/001/MONROM/YYYY', '000', 'MMYYYY', 1),
(43, 'SPK No', 'SPKMMYY00000', '00000', 'MMYY', 1),
(42, 'SRF Jaringan', 'SRF/N/MM/YY/000000', '000000', 'YY', 1),
(41, 'SRF Vast', 'SRF/V/MM/YY/000000', '000000', 'YY', 1),
(30, 'Transfer Stock', '00000/TS/MONROM/YYYY', '00000', 'MMYYYY', 1),
(45, 'Trouble Ticket No', '0000/OPS/TTI/MMYY', '0000', 'MMYY', 1);

DROP TABLE IF EXISTS `snrodet`;
CREATE TABLE IF NOT EXISTS `snrodet` (
  `snrodid` int(11) NOT NULL AUTO_INCREMENT,
  `snroid` int(11) NOT NULL,
  `curdd` int(11) DEFAULT NULL,
  `curmm` int(11) DEFAULT NULL,
  `curyy` int(11) DEFAULT NULL,
  `curvalue` int(11) DEFAULT NULL,
  `curcc` varchar(5) DEFAULT NULL,
  `curpt` varchar(5) DEFAULT NULL,
  `curpp` varchar(5) DEFAULT NULL,
  PRIMARY KEY (`snrodid`) USING BTREE,
  KEY `fk_snrod_snroid` (`snroid`),
  KEY `ix_snrodet` (`snrodid`,`snroid`,`curdd`,`curmm`,`curyy`,`curvalue`,`curcc`,`curpt`,`curpp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `translock`;
CREATE TABLE IF NOT EXISTS `translock` (
  `translockid` int(11) NOT NULL AUTO_INCREMENT,
  `menuname` varchar(50) DEFAULT NULL,
  `tableid` int(11) DEFAULT NULL,
  `lockedby` varchar(50) DEFAULT NULL,
  `lockeddate` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`translockid`),
  KEY `ix_translock` (`translockid`,`menuname`,`tableid`,`lockedby`,`lockeddate`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

INSERT INTO `translock` (`translockid`, `menuname`, `tableid`, `lockedby`, `lockeddate`) VALUES
(1, 'parameter', 1, 'admin', NULL),
(2, 'parameter', 1, 'admin', NULL),
(3, 'messages', 6, 'admin', NULL),
(4, 'messages', 6, 'admin', NULL);

DROP TABLE IF EXISTS `translog`;
CREATE TABLE IF NOT EXISTS `translog` (
  `translogid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `createddate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `useraction` varchar(50) NOT NULL,
  `newdata` text NOT NULL,
  `olddata` text NOT NULL,
  `menuname` varchar(50) NOT NULL,
  `tableid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`translogid`),
  KEY `ix_username` (`username`),
  KEY `ix_createddate` (`createddate`),
  KEY `ix_useraction` (`useraction`),
  KEY `ix_translog` (`translogid`,`username`,`createddate`,`useraction`,`menuname`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=4 ;

INSERT INTO `translog` (`translogid`, `username`, `createddate`, `useraction`, `newdata`, `olddata`, `menuname`, `tableid`) VALUES
(1, 'admin', '2013-03-15 10:55:10', 'new', '1', '1', 'company', 1),
(2, 'admin', '2013-03-15 10:55:10', 'update', '1 CV Prisma Data Abadi Ruko Taman Harapan Baru\r\nJl. Taman Harapan Baru Utara Blok N No 6 Bekasi 17131  40  021-90488878 / 087875097026 http://www.prismadataabadi.com admin@prismadataabadi.com logo.jpg  1', '1 CV Prisma Data Abadi Ruko Taman Harapan Baru\r\nJl. Taman Harapan Baru Utara Blok N No 6 Bekasi 17131  40  021-90488878 / 087875097026 http://www.prismadataabadi.com admin@prismadataabadi.com logo.jpg  1', 'company', 1),
(3, 'admin', '2013-03-19 11:31:52', 'update', '1 company Company 1', '1 company Company 1', 'messages', 1);

DROP TABLE IF EXISTS `useraccess`;
CREATE TABLE IF NOT EXISTS `useraccess` (
  `useraccessid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `realname` varchar(100) NOT NULL,
  `password` varchar(128) NOT NULL,
  `salt` varchar(128) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phoneno` varchar(50) DEFAULT NULL,
  `languageid` int(11) DEFAULT NULL,
  `recordstatus` tinyint(4) DEFAULT NULL,
  `theme` varchar(50) DEFAULT NULL,
  `iconfile` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`useraccessid`),
  UNIQUE KEY `username_UNIQUE` (`username`),
  KEY `ix_realname` (`realname`),
  KEY `ix_usernamepass` (`username`,`password`),
  KEY `ix_userlang` (`username`,`languageid`),
  KEY `fk_useraccess_lang` (`languageid`),
  KEY `ix_useraccess` (`useraccessid`,`username`,`realname`,`password`,`salt`,`email`,`phoneno`,`languageid`,`recordstatus`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;

INSERT INTO `useraccess` (`useraccessid`, `username`, `realname`, `password`, `salt`, `email`, `phoneno`, `languageid`, `recordstatus`, `theme`, `iconfile`) VALUES
(1, 'admin', 'Administrator', '7ae0afad7fd47b372fd7c444b3afe251', '4f08d56f6ff6e3.40159955', 'director@prismadataabadi.com', NULL, 1, 1, 'jumpforjoy', NULL);

DROP TABLE IF EXISTS `usergroup`;
CREATE TABLE IF NOT EXISTS `usergroup` (
  `usergroupid` int(11) NOT NULL,
  `useraccessid` int(11) NOT NULL,
  `groupaccessid` int(11) NOT NULL,
  PRIMARY KEY (`usergroupid`),
  KEY `fk_usergroup_user` (`useraccessid`),
  KEY `fk_usergroup_group` (`groupaccessid`),
  KEY `ix_usergroup` (`usergroupid`,`useraccessid`,`groupaccessid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `usergroup` (`usergroupid`, `useraccessid`, `groupaccessid`) VALUES
(1, 1, 1);

DROP TABLE IF EXISTS `usermenu`;
CREATE TABLE IF NOT EXISTS `usermenu` (
  `usermenuid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `useraccessid` int(11) NOT NULL,
  `menuaccessid` int(11) NOT NULL,
  PRIMARY KEY (`usermenuid`),
  KEY `FK_usermenu_user` (`useraccessid`),
  KEY `FK_usermenu_menu` (`menuaccessid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

INSERT INTO `usermenu` (`usermenuid`, `useraccessid`, `menuaccessid`) VALUES
(1, 1, 2),
(2, 1, 3),
(3, 1, 1);

DROP TABLE IF EXISTS `usertodo`;
CREATE TABLE IF NOT EXISTS `usertodo` (
  `usertodoid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `menuname` varchar(50) NOT NULL,
  `docno` varchar(50) NOT NULL DEFAULT '0',
  `recordstatus` tinyint(3) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`usertodoid`),
  KEY `ix_usertodo` (`usertodoid`,`username`,`menuname`,`docno`,`recordstatus`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `wfgroup`;
CREATE TABLE IF NOT EXISTS `wfgroup` (
  `wfgroupid` int(11) NOT NULL AUTO_INCREMENT,
  `workflowid` int(11) NOT NULL,
  `groupaccessid` int(11) NOT NULL,
  `wfbefstat` tinyint(4) NOT NULL,
  `wfrecstat` tinyint(4) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`wfgroupid`) USING BTREE,
  UNIQUE KEY `ix_wfgroup_wgb` (`workflowid`,`groupaccessid`,`wfbefstat`) USING BTREE,
  KEY `fk_wfgroup_group` (`groupaccessid`),
  KEY `ix_wfgroup_wfgbr` (`workflowid`,`groupaccessid`,`wfbefstat`,`wfrecstat`),
  KEY `ix_wfgroup_wgr` (`workflowid`,`groupaccessid`,`wfrecstat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `wfstatus`;
CREATE TABLE IF NOT EXISTS `wfstatus` (
  `wfstatusid` int(11) NOT NULL AUTO_INCREMENT,
  `workflowid` int(11) NOT NULL,
  `wfstat` tinyint(4) NOT NULL,
  `wfstatusname` varchar(50) CHARACTER SET latin1 NOT NULL,
  PRIMARY KEY (`wfstatusid`),
  KEY `fk_wfstatus_workflow` (`workflowid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

DROP TABLE IF EXISTS `workflow`;
CREATE TABLE IF NOT EXISTS `workflow` (
  `workflowid` int(11) NOT NULL AUTO_INCREMENT,
  `wfname` varchar(20) NOT NULL,
  `wfdesc` varchar(50) NOT NULL COMMENT 'wf description',
  `wfminstat` tinyint(4) NOT NULL,
  `wfmaxstat` tinyint(4) NOT NULL,
  `recordstatus` tinyint(4) NOT NULL,
  PRIMARY KEY (`workflowid`),
  UNIQUE KEY `uq_workflow_wfname` (`wfname`),
  KEY `ix_workflow` (`workflowid`,`wfname`,`wfdesc`,`wfminstat`,`wfmaxstat`,`recordstatus`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=84 ;

INSERT INTO `workflow` (`workflowid`, `wfname`, `wfdesc`, `wfminstat`, `wfmaxstat`, `recordstatus`) VALUES
(1, 'apppo', 'Approve PO', 1, 4, 1),
(2, 'appjournal', 'Approve Journal', 1, 3, 1),
(3, 'apppr', 'Approve PR', 1, 2, 1),
(7, 'listpo', 'List PO', 0, 1, 1),
(8, 'listjournal', 'list Journal', 0, 1, 1),
(9, 'listbs', 'List Beginning Stock', 0, 1, 1),
(10, 'appbs', 'Approve Beginning Stock', 1, 2, 1),
(11, 'appgi', 'Approve Goods Issue ', 1, 2, 1),
(12, 'listgi', 'List Goods Issue', 0, 1, 1),
(13, 'apppoc', 'Approve Purchase Order Customer', 1, 2, 1),
(14, 'listpoc', 'List Purchase Order Customer', 0, 1, 1),
(15, 'appso', 'Approve Sales Order', 1, 3, 1),
(16, 'listso', 'List Sales Order', 0, 3, 1),
(17, 'appdo', 'Approve Delivery Order', 1, 2, 1),
(18, 'listdo', 'List Delivery Order', 0, 1, 1),
(19, 'appevent', 'Approve Event', 1, 3, 1),
(20, 'listevent', 'List Event Admin', 0, 3, 1),
(21, 'listgr', 'List GR', 0, 1, 1),
(22, 'appgr', 'Approve GR', 1, 2, 1),
(23, 'listpr', 'List PR', 0, 3, 1),
(24, 'listproject', 'List Project', 0, 1, 1),
(25, 'listts', 'Transfer Stock', 0, 1, 1),
(26, 'appts', 'Approve Transfer Stock', 2, 3, 1),
(29, 'apppettycash', 'Approve Petty Cash', 1, 5, 1),
(30, 'listpettycash', 'List Petty Cash', 0, 4, 1),
(31, 'listempover', 'List Employee Over', 0, 2, 1),
(32, 'appempover', 'Approve Employee Over', 1, 3, 1),
(33, 'appproject', 'Approve Project', 1, 12, 1),
(37, 'appempsched', 'Approve Employee Schedule', 1, 2, 1),
(38, 'listempsched', 'List Employee Schedule', 0, 2, 1),
(39, 'apponleavetrans', 'Approve Onleave Trans', 1, 3, 1),
(40, 'listonleavetrans', 'List Onleave Trans', 0, 2, 1),
(41, 'apppermitexittrans', 'Approve Permit Exit Trans', 1, 3, 1),
(42, 'listpermitexittrans', 'List Permit Exit Trans', 0, 1, 1),
(43, 'appda', 'Approve Form Request', 1, 3, 1),
(44, 'listda', 'List Form Request', 0, 3, 1),
(45, 'apppermitintrans', 'Approve Permit In Trans', 1, 3, 1),
(46, 'listpermitintrans', 'List Permit In Trans', 0, 2, 1),
(47, 'appsicktrans', 'Approve Sickness Transaction', 1, 3, 1),
(48, 'listsicktrans', 'List Sickness Transaction', 1, 1, 1),
(49, 'insempsched', 'Insert Employee Schedule', 1, 2, 1),
(50, 'insda', 'Insert Form Request', 1, 1, 1),
(51, 'inspr', 'Insert PR', 1, 1, 1),
(52, 'inspo', 'Insert PO', 1, 1, 1),
(53, 'insgr', 'Insert GR', 1, 1, 1),
(54, 'insts', 'Insert Transfer Stock', 1, 1, 1),
(55, 'insbs', 'Insert BS', 1, 2, 1),
(56, 'listempspletter', 'List Employee SP Letter', 1, 2, 1),
(57, 'insproject', 'Insert Project', 1, 2, 1),
(58, 'appbaol', 'Approve BAOL', 1, 2, 1),
(59, 'listbaol', 'List BAOL', 1, 1, 1),
(60, 'insbaol', 'Insert BAOL', 1, 1, 1),
(61, 'insgenjournal', 'Insert General Journal', 1, 1, 1),
(62, 'insgi', 'Insert Goods Issue', 1, 1, 1),
(64, 'insso', 'Insert Sales Order', 1, 1, 1),
(66, 'insonleavetrans', 'Insert Onleave Trans', 1, 1, 1),
(67, 'insinvap', 'Insert Invoice AP', 1, 1, 1),
(68, 'listinvap', 'List Invoice AP', 1, 1, 1),
(69, 'appinvap', 'Approve Invoice AP', 1, 4, 1),
(70, 'appcbin', 'Approve Cash Bank Deposit', 1, 4, 1),
(71, 'listcbin', 'List Cash Bank Deposit', 1, 1, 1),
(72, 'inscbin', 'Insert Cash Bank Deposit', 1, 1, 1),
(73, 'appcbout', 'Approve Cash Bank Withdrawal', 1, 4, 1),
(74, 'listcbout', 'List Cash Bank Withdrawal', 1, 1, 1),
(75, 'inscbout', 'Insert Cash Bank Withdrawal', 1, 1, 1),
(76, 'insinvar', 'Insert Invoice AR', 1, 1, 1),
(77, 'listinvar', 'List Invoice AR', 1, 1, 1),
(78, 'appinvar', 'Approve Invoice AR', 1, 4, 1),
(80, 'rejgenjournal', 'Reject General Journal', 1, 5, 1),
(81, 'prigenjournal', 'Print General Journal', 1, 5, 1),
(82, 'priso', 'Print Sales Order', 1, 3, 1),
(83, 'rejso', 'Reject Sales Order', 1, 3, 1);

DROP TABLE IF EXISTS `yiisession`;
CREATE TABLE IF NOT EXISTS `yiisession` (
  `id` char(32) NOT NULL,
  `expire` int(11) DEFAULT NULL,
  `data` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `yiisession` (`id`, `expire`, `data`) VALUES
('48d76v37gu5gfl9lvihusudd86', 1363763552, 'a458ffbadb8ba7f186312b95d52901ef__id|s:5:"admin";a458ffbadb8ba7f186312b95d52901ef__name|s:5:"admin";a458ffbadb8ba7f186312b95d52901ef__states|a:0:{}');


ALTER TABLE `catalogsys`
  ADD CONSTRAINT `FK_catalogsys_lang` FOREIGN KEY (`languageid`) REFERENCES `language` (`languageid`),
  ADD CONSTRAINT `FK_catalogsys_mess` FOREIGN KEY (`messagesid`) REFERENCES `messages` (`messagesid`);

ALTER TABLE `city`
  ADD CONSTRAINT `fk_city_province` FOREIGN KEY (`provinceid`) REFERENCES `province` (`provinceid`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `groupmenu`
  ADD CONSTRAINT `FK_groupmenu_group` FOREIGN KEY (`groupaccessid`) REFERENCES `groupaccess` (`groupaccessid`),
  ADD CONSTRAINT `FK_groupmenu_menu` FOREIGN KEY (`menuaccessid`) REFERENCES `menuaccess` (`menuaccessid`);

ALTER TABLE `groupmenuauth`
  ADD CONSTRAINT `fk_groupmenuauth_1` FOREIGN KEY (`groupaccessid`) REFERENCES `groupaccess` (`groupaccessid`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_groupmenuauth_2` FOREIGN KEY (`menuauthid`) REFERENCES `menuauth` (`menuauthid`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `province`
  ADD CONSTRAINT `fk_province_country` FOREIGN KEY (`countryid`) REFERENCES `country` (`countryid`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `snrodet`
  ADD CONSTRAINT `fk_snrod_snroid` FOREIGN KEY (`snroid`) REFERENCES `snro` (`snroid`);

ALTER TABLE `useraccess`
  ADD CONSTRAINT `fk_useraccess_lang` FOREIGN KEY (`languageid`) REFERENCES `language` (`languageid`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `usergroup`
  ADD CONSTRAINT `fk_usergroup_group` FOREIGN KEY (`groupaccessid`) REFERENCES `groupaccess` (`groupaccessid`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_usergroup_user` FOREIGN KEY (`useraccessid`) REFERENCES `useraccess` (`useraccessid`) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE `usermenu`
  ADD CONSTRAINT `FK_usermenu_user` FOREIGN KEY (`useraccessid`) REFERENCES `useraccess` (`useraccessid`),
  ADD CONSTRAINT `FK_usermenu_menu` FOREIGN KEY (`menuaccessid`) REFERENCES `menuaccess` (`menuaccessid`);

ALTER TABLE `wfgroup`
  ADD CONSTRAINT `fk_wfgroup_group` FOREIGN KEY (`groupaccessid`) REFERENCES `groupaccess` (`groupaccessid`),
  ADD CONSTRAINT `fk_wfgroup_workflow` FOREIGN KEY (`workflowid`) REFERENCES `workflow` (`workflowid`);

ALTER TABLE `wfstatus`
  ADD CONSTRAINT `fk_wfstatus_workflow` FOREIGN KEY (`workflowid`) REFERENCES `workflow` (`workflowid`);
SET FOREIGN_KEY_CHECKS=1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
