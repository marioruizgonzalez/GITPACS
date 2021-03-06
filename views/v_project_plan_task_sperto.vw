CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_PROJECT_PLAN_TASK_SPERTO AS
SELECT PA_TASKS.TASK_ID,
          PA_TASKS.PROJECT_ID,
          PA_TASKS.TASK_NUMBER,
          PA_TASKS.CREATION_DATE,
          PA_TASKS.LAST_UPDATE_DATE,
          PA_TASKS.TASK_NAME,
          PA_TASKS.TOP_TASK_ID,
          PA_TASKS.WBS_LEVEL,
          PA_TASKS.PARENT_TASK_ID,
          PA_TASKS.DESCRIPTION,
          PA_TASKS.CARRYING_OUT_ORGANIZATION_ID,
          PA_TASKS.START_DATE,
          PA_TASKS.ACTUAL_START_DATE,
          PA_TASKS.COMPLETION_DATE,
          PA_TASKS.ACTUAL_FINISH_DATE
     FROM PA.PA_TASKS@OFNX_SPERTO, pa.PA_PROJECTS_ALL@OFNX_SPERTO
    WHERE     PA.PA_TASKS.PROJECT_ID = pa.PA_PROJECTS_ALL.PROJECT_ID
          AND PA.PA_TASKS.START_DATE > TO_DATE ('30/12/2018', 'dd/mm/yyyy');

