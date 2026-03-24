package app

import "fmt"

type moduleInitializer struct {
	name string
	init func(genesis Genesis) error
}

type ModuleManager struct {
	modules []moduleInitializer
}

func NewModuleManager() *ModuleManager {
	return &ModuleManager{
		modules: make([]moduleInitializer, 0, 4),
	}
}

func (m *ModuleManager) Register(name string, init func(genesis Genesis) error) {
	m.modules = append(m.modules, moduleInitializer{
		name: name,
		init: init,
	})
}

func (m *ModuleManager) InitGenesis(genesis Genesis) error {
	for _, module := range m.modules {
		if err := module.init(genesis); err != nil {
			return fmt.Errorf("%s init genesis failed: %w", module.name, err)
		}
	}
	return nil
}

func (m *ModuleManager) Names() []string {
	out := make([]string, 0, len(m.modules))
	for _, module := range m.modules {
		out = append(out, module.name)
	}
	return out
}
