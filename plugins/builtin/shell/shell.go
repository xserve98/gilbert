package shell

import (
	"fmt"
	"github.com/mitchellh/mapstructure"
	"github.com/x1unix/gilbert/logging"
	"github.com/x1unix/gilbert/manifest"
	"github.com/x1unix/gilbert/plugins"
	"github.com/x1unix/gilbert/scope"
	"os"
	"os/exec"
)

type Params struct {
	// Command is command to execute
	Command string

	// Silent param hides stdout and stderr from output
	Silent bool

	// RawOutput removes logging output decoration from stdout and stderr
	RawOutput bool

	// Shell is default shell to start
	Shell string

	// ShellExecParam is param used by shell to pass command.
	//
	// Example: "bash -c "your command"
	ShellExecParam string

	// WorkDir is current working directory
	WorkDir string

	// Env is set of environment variables
	Env Environment
}

func (p *Params) createProcess(ctx *scope.Context) (*exec.Cmd, error) {
	// TODO: check if Shell or ShellExecParam are empty
	cmdstr, err := ctx.ExpandVariables(p.preparedCommand())
	if err != nil {
		return nil, err
	}

	cmd := exec.Command(p.Shell, p.ShellExecParam, cmdstr)
	cmd.Dir = p.WorkDir

	// TODO: inherit global vars
	if !p.Env.Empty() {
		cmd.Env = p.Env.ToArray(os.Environ()...)
	} else {
		cmd.Env = os.Environ()
	}

	return cmd, nil
}

func newParams(ctx *scope.Context) Params {
	p := defaultParams()
	p.WorkDir = ctx.Environment.ProjectDirectory

	return p
}

func NewShellPlugin(context *scope.Context, params manifest.RawParams, log logging.Logger) (plugins.Plugin, error) {
	p := newParams(context)

	if err := mapstructure.Decode(params, &p); err != nil {
		return nil, fmt.Errorf("failed to read configuration: %s", err)
	}

	return &Plugin{
		context: context,
		params:  p,
		log:     log,
	}, nil
}