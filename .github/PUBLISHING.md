# Publishing tcs.jira to the PowerShell Gallery

Releases of `tcs.jira` are built by GitHub Actions workflows that call the shared workflows in
[ntatschner/tcs-shared-workflows](https://github.com/ntatschner/tcs-shared-workflows).

## Workflows

| File | Name | What it does |
| --- | --- | --- |
| `.github/workflows/ci-validate.yml` | CI Validate | Validates the manifest, runs PSScriptAnalyzer, the smoke tests (`.github/scripts/module-smoke-tests.ps1`) and Pester on Windows PowerShell 5.1 and PowerShell 7 (Windows, Linux, macOS). Runs on pull requests and pushes to `main`. |
| `.github/workflows/create-version-tag.yml` | Create Version Tag | Runs after a successful CI Validate on `main`, when the manifest changes on `main`, or manually. Creates the tag `v<ModuleVersion>` when `ModuleVersion` in `modules/tcs.jira/tcs.jira.psd1` is greater than the latest tag. |
| `.github/workflows/generate-docs.yml` | Generate PowerShell Documentation | Generates the markdown help in `docs/` and the external help in `modules/tcs.jira/en-GB/` with PlatyPS and commits them (pull request runs only check that the docs generate). |
| `.github/workflows/publish-to-psgallery.yml` | Publish to PSGallery | Validates the module, publishes it to the PowerShell Gallery and creates a GitHub release. Runs on a pushed `v*` tag or manually. |

## Prerequisites

### PowerShell Gallery API key

1. Sign in to the [PowerShell Gallery](https://www.powershellgallery.com/) and open **API Keys**.
2. Create a key with the **Push new packages and package versions** scope and a glob pattern that
   covers `tcs.jira` (for example `tcs.jira` or `tcs.*`).
3. Copy the key.

### Repository secret

1. In the GitHub repository open **Settings** > **Secrets and variables** > **Actions**.
2. Add a repository secret named `PSGALLERY_API_KEY` with the key as its value.

The tag and docs workflows use the built-in `GITHUB_TOKEN`; no other secret is needed.

## Releasing a new version

1. Update `ModuleVersion` in `modules/tcs.jira/tcs.jira.psd1` (semantic versioning) and add a
   section for the version to `CHANGELOG.md`.
2. Merge the change to `main` through a pull request.
3. CI Validate runs on `main`. When it succeeds, Create Version Tag creates and pushes the tag
   `v<version>` (for example `v0.1.0`).
4. **Start the publish manually.** A tag pushed by a workflow with `GITHUB_TOKEN` does not trigger
   other workflows, so the tag from step 3 does not start Publish to PSGallery. Open
   **Actions** > **Publish to PSGallery** > **Run workflow**, choose the tag `v<version>` in
   **Use workflow from**, and run it.
5. Check the run, the GitHub release and the module page on the PowerShell Gallery.

To have the tag start the publish automatically, change `repo-token` in
`create-version-tag.yml` from `secrets.GITHUB_TOKEN` to a secret holding a personal access token (or
GitHub App token) with `contents: write` on this repository. A tag pushed with that token triggers
Publish to PSGallery.

A tag pushed by a person (`git tag v0.1.0` then `git push origin v0.1.0`) also triggers the publish.

### Force publish

The manual run has a **Force publish** option that publishes even if the version already exists in
the gallery. Leave it off for normal releases; the gallery does not accept the same version twice
from a normal publish, so bump `ModuleVersion` instead.

## Troubleshooting

- **API key rejected**: check the secret is named exactly `PSGALLERY_API_KEY`, the key has not
  expired, has push rights and its glob covers `tcs.jira`.
- **Version already exists**: bump `ModuleVersion` in the manifest.
- **No tag was created**: `ModuleVersion` must be greater than the latest `v*` tag, and CI Validate
  must have succeeded on `main`.
- **Tag exists but nothing was published**: expected when the tag was created by the workflow; run
  Publish to PSGallery manually on the tag (step 4 above).
- **Validation or import failures**: the run log shows the PSScriptAnalyzer findings or the import
  error. `tcs.core` (a RequiredModule) is installed from the gallery during the run.

## Security

- Never commit API keys; keep them in repository secrets.
- Rotate the gallery API key regularly and scope it to the tcs modules only.
- Consider an environment with required reviewers for the publish job.
