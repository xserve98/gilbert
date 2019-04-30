package http

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"net/http"
	"net/url"
	"os"
	"path/filepath"

	"github.com/go-gilbert/gilbert/log"
	"github.com/go-gilbert/gilbert/plugins/support"
	"github.com/go-gilbert/gilbert/storage"
	"github.com/go-gilbert/gilbert/tools/fs"
	"github.com/go-gilbert/gilbert/tools/web"
)

const (
	providerName       = "http"
	defaultPluginFName = "plugin"
)

func getPluginDirectory(uri string) string {
	hasher := md5.New()
	hasher.Write([]byte(uri))
	return filepath.Join(providerName, hex.EncodeToString(hasher.Sum(nil)))
}

// ImportHandler is web source handler for plugins
func ImportHandler(ctx context.Context, uri *url.URL) (string, error) {
	strUri := uri.String()
	dir, err := storage.Path(storage.Plugins, getPluginDirectory(strUri))
	if err != nil {
		return "", err
	}

	// TODO: determine real file name from web response
	pluginPath := filepath.Join(dir, support.AddPluginExtension(defaultPluginFName))
	exists, err := fs.Exists(pluginPath)
	if err != nil {
		return "", err
	}

	if !exists {
		log.Default.Debugf("http: init plugin directory: '%s'", dir)
		if err = os.MkdirAll(dir, support.PluginPermissions); err != nil {
			return "", err
		}

		log.Default.Infof("Downloading plugin file from '%s'...", strUri)
		if err := web.ProgressDownloadFile(&http.Client{}, strUri, pluginPath); err != nil {
			return "", err
		}
	}

	return pluginPath, nil
}
