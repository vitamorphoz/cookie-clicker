# Git Guide: Rebase и Merge / Rebase and Merge

## На русском / In Russian

### Что такое divergent branches (расходящиеся ветки)?

Когда вы видите ошибку "divergent branches", это означает, что ваша локальная ветка и удаленная ветка разошлись - в них есть разные коммиты, которых нет друг у друга.

### Merge (Слияние)

**Merge** объединяет две ветки, создавая новый коммит слияния.

**Преимущества:**
- Сохраняет полную историю коммитов
- Безопасный метод, не перезаписывает историю
- Показывает, когда и как ветки были объединены

**Недостатки:**
- Создает дополнительные коммиты слияния
- История может стать запутанной при частых слияниях

**Команда:**
```bash
git pull --no-rebase
# или
git config pull.rebase false
git pull
```

### Rebase (Перебазирование)

**Rebase** перемещает ваши локальные коммиты поверх коммитов из удаленной ветки, создавая линейную историю.

**Преимущества:**
- Создает чистую, линейную историю
- Легче читать историю коммитов
- Нет лишних коммитов слияния

**Недостатки:**
- Перезаписывает историю коммитов
- Может быть опасным при работе в команде
- Не показывает, когда происходило слияние

**Команда:**
```bash
git pull --rebase
# или
git config pull.rebase true
git pull
```

### Fast-forward only (Только быстрая перемотка)

**Fast-forward** работает только когда ваша локальная ветка не содержит новых коммитов. Git просто "перематывает" указатель на последний коммит.

**Команда:**
```bash
git pull --ff-only
# или
git config pull.ff only
git pull
```

### Как решить вашу проблему?

Исходя из сообщения об ошибке, у вас есть три варианта:

#### Вариант 1: Merge (Рекомендуется для начинающих)
```bash
git config pull.rebase false
git pull
```
Это создаст коммит слияния и объединит изменения.

#### Вариант 2: Rebase (Для чистой истории)
```bash
git config pull.rebase true
git pull
```
Это переместит ваши локальные коммиты поверх удаленных изменений.

#### Вариант 3: Fast-forward only (Самый строгий)
```bash
git config pull.ff only
git pull
```
Это сработает только если у вас нет локальных коммитов. Если есть, нужно будет использовать merge или rebase.

### Глобальная настройка

Чтобы установить настройку для всех репозиториев:
```bash
git config --global pull.rebase false  # для merge
# или
git config --global pull.rebase true   # для rebase
```

---

## In English

### What are divergent branches?

When you see the error "divergent branches", it means your local branch and remote branch have diverged - they contain different commits that the other doesn't have.

### Merge

**Merge** combines two branches by creating a new merge commit.

**Advantages:**
- Preserves complete commit history
- Safe method, doesn't rewrite history
- Shows when and how branches were combined

**Disadvantages:**
- Creates additional merge commits
- History can become cluttered with frequent merges

**Command:**
```bash
git pull --no-rebase
# or
git config pull.rebase false
git pull
```

### Rebase

**Rebase** moves your local commits on top of the remote commits, creating a linear history.

**Advantages:**
- Creates clean, linear history
- Easier to read commit history
- No extra merge commits

**Disadvantages:**
- Rewrites commit history
- Can be dangerous when working in a team
- Doesn't show when merging happened

**Command:**
```bash
git pull --rebase
# or
git config pull.rebase true
git pull
```

### Fast-forward only

**Fast-forward** only works when your local branch has no new commits. Git simply "fast-forwards" the pointer to the latest commit.

**Command:**
```bash
git pull --ff-only
# or
git config pull.ff only
git pull
```

### How to solve your problem?

Based on the error message, you have three options:

#### Option 1: Merge (Recommended for beginners)
```bash
git config pull.rebase false
git pull
```
This will create a merge commit and combine the changes.

#### Option 2: Rebase (For clean history)
```bash
git config pull.rebase true
git pull
```
This will move your local commits on top of remote changes.

#### Option 3: Fast-forward only (Strictest)
```bash
git config pull.ff only
git pull
```
This only works if you have no local commits. If you do, you'll need to use merge or rebase.

### Global configuration

To set the configuration for all repositories:
```bash
git config --global pull.rebase false  # for merge
# or
git config --global pull.rebase true   # for rebase
```

## Visual Comparison / Визуальное сравнение

### Before / До:
```
Remote:  A---B---C---D
                  \
Local:   A---B---C---E---F
```

### After Merge / После Merge:
```
A---B---C---D-------M
         \         /
          E---F---/
```

### After Rebase / После Rebase:
```
A---B---C---D---E'---F'
```

## Best Practices / Лучшие практики

**Используйте Merge когда:**
- Работаете в команде
- Хотите сохранить полную историю
- Не уверены, что делать

**Используйте Rebase когда:**
- Работаете над личной веткой
- Хотите чистую историю
- Понимаете последствия перезаписи истории

**Use Merge when:**
- Working in a team
- Want to preserve complete history
- Unsure what to do

**Use Rebase when:**
- Working on a personal branch
- Want clean history
- Understand the consequences of rewriting history
