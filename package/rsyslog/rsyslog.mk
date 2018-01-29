################################################################################
#
# rsyslog
#
################################################################################

RSYSLOG_VERSION = 8.22.0
RSYSLOG_SITE = http://rsyslog.com/files/download/rsyslog
RSYSLOG_LICENSE = GPLv3, LGPLv3, Apache-2.0
RSYSLOG_LICENSE_FILES = COPYING COPYING.LESSER COPYING.ASL20
RSYSLOG_DEPENDENCIES = zlib libestr liblogging libfastjson host-pkgconf
RSYSLOG_CONF_ENV = ac_cv_prog_cc_c99='-std=c99'
RSYSLOG_PLUGINS = imdiag imfile impstats imptcp \
	mmanon mmaudit mmfields mmjsonparse mmpstrucdata mmsequence mmutf8fix \
	mail omprog omruleset omstdout omuxsock \
	pmaixforwardedfrom pmciscoios pmcisconames pmlastmsg pmsnare
RSYSLOG_CONF_OPTS = --disable-generate-man-pages \
	$(foreach x,$(call qstrip,$(RSYSLOG_PLUGINS)),--enable-$(x))

# Build after BusyBox
ifeq ($(BR2_PACKAGE_BUSYBOX),y)
RSYSLOG_DEPENDENCIES += busybox
endif

ifeq ($(BR2_PACKAGE_GNUTLS),y)
RSYSLOG_DEPENDENCIES += gnutls
RSYSLOG_CONF_OPTS += --enable-gnutls
else
RSYSLOG_CONF_OPTS += --disable-gnutls
endif

ifeq ($(BR2_PACKAGE_LIBEE),y)
RSYSLOG_DEPENDENCIES += libee
endif

ifeq ($(BR2_PACKAGE_LIBGCRYPT),y)
RSYSLOG_DEPENDENCIES += libgcrypt
RSYSLOG_CONF_ENV += LIBGCRYPT_CONFIG=$(STAGING_DIR)/usr/bin/libgcrypt-config
RSYSLOG_CONF_OPTS += --enable-libgcrypt
else
RSYSLOG_CONF_OPTS += --disable-libgcrypt
endif

ifeq ($(BR2_PACKAGE_MYSQL),y)
RSYSLOG_DEPENDENCIES += mysql
RSYSLOG_CONF_OPTS += --enable-mysql
RSYSLOG_CONF_ENV += ac_cv_prog_MYSQL_CONFIG=$(STAGING_DIR)/usr/bin/mysql_config
else
RSYSLOG_CONF_OPTS += --disable-mysql
endif

ifeq ($(BR2_PACKAGE_POSTGRESQL),y)
RSYSLOG_DEPENDENCIES += postgresql
RSYSLOG_CONF_OPTS += --enable-pgsql
RSYSLOG_CONF_ENV += ac_cv_prog_PG_CONFIG=$(STAGING_DIR)/usr/bin/pg_config
else
RSYSLOG_CONF_OPTS += --disable-pgsql
endif

ifeq ($(BR2_PACKAGE_UTIL_LINUX_LIBUUID),y)
RSYSLOG_DEPENDENCIES += util-linux
RSYSLOG_CONF_OPTS += --enable-uuid
else
RSYSLOG_CONF_OPTS += --disable-uuid
endif

ifeq ($(BR2_INIT_SYSTEMD),y)
RSYSLOG_CONF_OPTS += \
	--enable-imjournal \
	--enable-omjournal \
	--with-systemdsystemunitdir=/usr/lib/systemd/system
RSYSLOG_DEPENDENCIES += systemd
else
RSYSLOG_CONF_OPTS += \
	--disable-imjournal \
	--disable-omjournal
endif

define RSYSLOG_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D package/rsyslog/S01logging \
		$(TARGET_DIR)/etc/init.d/S01logging
endef

# The rsyslog.service is installed by rsyslog, but the link is not created
# so the service is not enabled.
# We need to create another link which is due to the fact that the
# rsyslog.service contains an Alias=
# If we were to use systemctl enable to enable the service, it would
# create both, so we mimic that.
define RSYSLOG_INSTALL_INIT_SYSTEMD
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf ../../../../usr/lib/systemd/system/rsyslog.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/rsyslog.service
	ln -sf ../../../../usr/lib/systemd/system/rsyslog.service \
		$(TARGET_DIR)/etc/systemd/system/syslog.service
endef

define RSYSLOG_INSTALL_CONF
	$(INSTALL) -m 0644 -D $(@D)/platform/redhat/rsyslog.conf \
		$(TARGET_DIR)/etc/rsyslog.conf
	mkdir -p $(TARGET_DIR)/etc/rsyslog.d
endef

RSYSLOG_POST_INSTALL_TARGET_HOOKS += RSYSLOG_INSTALL_CONF

$(eval $(autotools-package))
