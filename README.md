# ocp-account-creation
Cheat sheet for creating an new admin and developer account on OCP using htpasswd authentication


Setting up htpasswd authentication for an OpenShift cluster involves creating a user file, securing it as a Secret, configuring an OAuth identity provider, and then applying Role-Based Access Control (RBAC) to grant the necessary permissions to the users.

Here are the steps to create an admin user with cluster-admin access and a developer user with the ability to create and manage projects.

You must be logged in to your OpenShift cluster as a user with cluster-admin privileges (e.g., using the initial kubeadmin credentials) to perform these steps.

1. Create the htpasswd File

Use the htpasswd utility (you may need to install the httpd-tools or apache2-utils package) to create and populate a user file.

Create the file and add the admin user:
Use the -c option to create the file and -B for bcrypt encryption.

```
htpasswd -c -B users.htpasswd admin
```

# The command will prompt you to enter and confirm the password for 'admin'.

Add the developer user:
Omit the -c option to append to the existing file.

```
htpasswd -B users.htpasswd developer
```

# The command will prompt you to enter and confirm the password for 'developer'.
Verify the file contents:
The file should contain two lines, each with a username and a hashed password.

```
cat users.htpasswd
```

**Note the passwords in `users.htpasswd` are currently `redhat123!` for example purposes only and can/should be changed.**

2. Create the OpenShift Secret

The htpasswd file must be stored as a Secret in the openshift-config namespace so the cluster can access it for authentication.

```
oc create secret generic htpass-secret \
  --from-file=htpasswd=users.htpasswd \
  -n openshift-config
```

3. Configure the HTPasswd Identity Provider

Next, you need to configure the OpenShift OAuth custom resource to use the new Secret as an identity provider.

Create a YAML file (e.g., `htpasswd-provider.yaml`) with the following content. This configuration adds a new identity provider named local-htpasswd that references the secret you just created.


```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: local-htpasswd
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
```

If you already have other identity providers configured, you'll need to use `oc edit oauth cluster` and add this stanza to the `spec.identityProviders` list.

Apply the configuration:

```
oc apply -f htpasswd-provider.yaml
```

The OpenShift OAuth server will restart, and the new login option (typically named local-htpasswd) will appear on the login screen.

4. Grant User Permissions (RBAC)

Once the identity provider is configured, you need to assign roles to the users to define their access levels.

- Assign cluster-admin to the admin user

The cluster-admin role is a super-user role that grants full administrative control over the entire cluster.

```
oc adm policy add-cluster-role-to-user cluster-admin admin
```

- Grant Project Creation and Management for developer

The built-in OpenShift role self-provisioner allows a user to create new projects (namespaces). By default, OpenShift grants a user the admin role within a project they create, allowing them to manage all resources within it.


```
oc adm policy add-cluster-role-to-user self-provisioner developer
```

5. Test and Finalize

Log out and then log in using the local-htpasswd identity provider option with the credentials you set.

Log in as admin and run `oc whoami --show-groups` to verify system:authenticated:oauth and check cluster access (e.g., oc get nodes).

Log in as developer and try to create a new project: `oc new-project my-test-project`. This should succeed, confirming the self-provisioner role is active.

(Optional but recommended) Once you have confirmed the new admin account works, follow cluster security best practices to remove the temporary kubeadmin user.