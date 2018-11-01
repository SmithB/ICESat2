# ICESat2
Scripts for processing and viewing ICESat-2 data

## Recipe to contribute

There are two main ways (workflows) to contribute to the repo while minimizing update conflicts.


## 1) Branch Workflow

- You will work directly with the original repo (on Ben's GitHub).
- Think of `branches` as folders.  
- The stable code is in the `master` branch.
- You will create a `work` branch (a copy of `master`) and modify this.
- When you are done with edits/additions you will merge `work` with `master`.
- This will check inconsistencies between branches and let you know it's safe to merge.

1) Clone the original repo to your local machine:
    ```
    git clone https://github.com/SmithB/ICESat2.gi://github.com/SmithB/ICESat2.git
    ```

2) Create a new branch (e.g. `yourname`) locally where you will edit/add code:
    ```
    cd ICESat2
    git checkout -b yourname master
    ```

3) Push the new branch to the remote repo:
    ```
    git push -u origin yourname
    ```

4) Now you're free to edit/add code. Then save changes locally:
    ```
    git add <program.py>
    git commit -m 'some message'
    ```

5) Push the changes to the remote repo (to `yourname` branch):
    ```
    git push
    ```

6) Now go to the [ICESat2 repo](https://github.com/SmithB/ICESat2) and click **Compare & pull request**. This will allow you to merge `yourname` with `master` if there are no inconsistencies. If there are conflicts, solve those.


## 2) Fork Workflow

- You will create a copy of the official repo on your own GitHub account.
- You will edit and make additions to this copy.
- You will create a Pull Request to incorporate your contribution to the official repo.
- Any Collaborator (give your GitHub username to Ben) can review and approve the merge.

1) Go to the [ICESat2 repo](https://github.com/SmithB/ICESat2) and click **Fork** (upper-right corner) to make a copy on your own GitHub account.

2) Clone the forked repo to your local machine:
    ```
    git clone https://github.com/<yourname>/ICESat2.git
    ```

3) Now you're free to edit/add code. Then save changes locally:
    ```
    git add <program.py>
    git commit -m 'some message'
    ```

4) Push the changes to the remote copy repo (i.e. to your GitHub):
    ```
    git push
    ```

5) Go to the [ICESat2 repo](https://github.com/SmithB/ICESat2) and click **New pull request** to merge your changes with the original repo.

6) Click **compare across forks**, and select your fork from the **3rd drop-down menu**.

7) Cick **Create pull request**. If there are no conflicts, click **Merge pull request**. If there are conflicts, fix those.



## Some tips

If you are really confident that your changes/additions will not break anything, you can skip the branch creation and just do steps `(1)`, `(4)` and `(5)`: 
    ```
    git clone https://github.com/SmithB/ICESat2.gi://github.com/SmithB/ICESat2.git
    cd ICESat2
    git add <program.py>
    git commit -m 'some message'
    git push
    ```

That's it.

To keep your forked repo in sync with the original (upstream) repo, first point to it:
    ```
    git remote add upstream https://github.com/SmithB/ICESat2.git
    ```

then every so often bring your forked repo up-to-date with the original: 
    ```
    git fetch upstream
    git checkout master
    git merge upstream/master
    git push
    ```

Before editing/adding code to your local repo (on your machine) make sure it's up-to-date w.r.t. the remote repo (on GitHub), do:
    ```
    git pull
    ```


## Further (easy) reading

    [Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)
    [Fork Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow)
    [Working with Forks](https://help.github.com/articles/working-with-forks/)
    k



