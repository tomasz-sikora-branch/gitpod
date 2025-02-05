// Copyright (c) 2021 Gitpod GmbH. All rights reserved.
// Licensed under the GNU Affero General Public License (AGPL).
// See License.AGPL.txt in the project root for license information.

package wsproxy

import (
	"github.com/gitpod-io/gitpod/installer/pkg/common"
	"github.com/gitpod-io/gitpod/installer/pkg/config/v1/experimental"

	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

func role(ctx *common.RenderContext) ([]runtime.Object, error) {
	rules := []rbacv1.PolicyRule{
		{
			APIGroups: []string{""},
			Resources: []string{"pods"},
			Verbs: []string{
				"get",
				"list",
				"watch",
			},
		},
	}

	ctx.WithExperimental(func(ucfg *experimental.Config) error {
		if ucfg.Workspace != nil && ucfg.Workspace.UseWsmanagerMk2 {
			rules = append(rules, rbacv1.PolicyRule{
				APIGroups: []string{"workspace.gitpod.io"},
				Resources: []string{"workspaces"},
				Verbs: []string{
					"get",
					"list",
					"watch",
				},
			})
		}

		return nil
	})

	return []runtime.Object{&rbacv1.Role{
		TypeMeta: common.TypeMetaRole,
		ObjectMeta: metav1.ObjectMeta{
			Name:      Component,
			Namespace: ctx.Namespace,
			Labels:    common.DefaultLabels(Component),
		},
		Rules: rules,
	},
	}, nil
}
