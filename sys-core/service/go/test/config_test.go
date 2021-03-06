package db_test

import (
	"fmt"
	commonCfg "go.amplifyedge.org/sys-share-v2/sys-core/service/config/common"
	"testing"

	"github.com/stretchr/testify/assert"

	corecfg "go.amplifyedge.org/sys-v2/sys-core/service/go"
)



func testNewSysCoreConfig(t *testing.T) {
	baseTestDir := "./config"
	// Test nonexistent config
	_, err := corecfg.NewConfig("./nonexistent.yml")
	assert.Error(t, err)
	// Test valid config
	sysCoreCfg, err = corecfg.NewConfig(fmt.Sprintf("%s/%s", baseTestDir, "valid.yml"))
	assert.NoError(t, err)
	expected := &corecfg.SysCoreConfig{
		SysCoreConfig: commonCfg.Config{
			DbConfig: commonCfg.DbConfig{
				Name:             "amplify-cms.db",
				EncryptKey:       "testkey!@",
				RotationDuration: 1,
				DbDir:            "./db",
				DeletePrevious:   true,
			},
			CronConfig: commonCfg.CronConfig{
				BackupSchedule: "@daily",
				RotateSchedule: "@every 3s",
				BackupDir:      "./db/backups",
			},
		},
	}
	assert.Equal(t, expected, sysCoreCfg)
}
