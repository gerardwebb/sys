package filesvc

import (
	"go.amplifyedge.org/sys-share-v2/sys-core/service/logging"
	"google.golang.org/grpc"

	coreRpc "go.amplifyedge.org/sys-share-v2/sys-core/service/go/rpc/v2"
	"go.amplifyedge.org/sys-v2/sys-core/service/go/pkg/coredb"
	"go.amplifyedge.org/sys-v2/sys-core/service/go/pkg/filesvc/repo"
)

type SysFileService struct {
	repo *repo.SysFileRepo
}

func NewSysFileService(cfg *FileServiceConfig, l logging.Logger) (*SysFileService, error) {
	db, err := coredb.NewCoreDB(l, &cfg.DBConfig, nil)
	if err != nil {
		return nil, err
	}
	fileRepo, err := repo.NewSysFileRepo(db, l)
	if err != nil {
		return nil, err
	}
	return &SysFileService{repo: fileRepo}, nil
}

func (s *SysFileService) RegisterService(srv *grpc.Server) {
	coreRpc.RegisterFileServiceServer(srv, s.repo)
}
