## Description

Brief description of the changes.

## Type of Change

- [ ] 🐛 Bug fix
- [ ] ✨ New compliance control
- [ ] 📝 Documentation update
- [ ] 🔧 Configuration improvement
- [ ] 🔐 Security enhancement

## Compliance Framework

<!-- Which NIS2/DORA/ISO 27001 article does this implement? -->

- [ ] NIS2 Article: ___
- [ ] DORA Article: ___
- [ ] ISO 27001 Control: ___
- [ ] BSI IT-Grundschutz: ___

## Checklist

- [ ] `terraform fmt -recursive` applied
- [ ] `opa test policies-as-code/opa/ -v` passes
- [ ] `make validate` passes locally
- [ ] NIS2/DORA article referenced in code comments (`NIS2Control` tag)
- [ ] `docs/compliance-mapping.md` updated (if new control)
- [ ] No secrets or credentials in code
- [ ] No `.tfplan` or `.tfstate` files committed

## Testing

```bash
# Commands used to test this change
make validate
```

## Related Issue

Fixes #___
