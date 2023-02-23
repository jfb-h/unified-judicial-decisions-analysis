library(tidyverse)
library(mgcv)
library(ggplot)

df = read_csv("data_R.csv")
df$date_num = as.numeric(df$date)

names = df |> 
    group_by(chairman) |> 
    summarize(n=n()) |> 
    arrange(desc(n)) |> 
    pull(chairman) |> 
    head(12)

df_top = filter(df, chairman %in% names)
df_top = df_top |>
    group_by(chairman) |> 
    mutate(counter = row_number(chairman))

plot_judges <- function(df_top, x) {
    ggplot(df_top, aes({{x}}, outcome)) +
        geom_smooth(method="glm", method.args=list(family="binomial")) +
        facet_wrap(~chairman, scales="free") +
        geom_rug(data=filter(df_top, outcome==1), aes({{x}}, outcome), sides="t") +
        geom_rug(data=filter(df_top, outcome==0), aes({{x}}, outcome), sides="b")
}

# plot_judge <- function(judge) {
#     ggplot(filter(df, chairman == {{judge}}), aes(date, outcome)) + 
#         geom_smooth(method="glm", method.args=list(family="binomial")) + 
#         geom_rug(data=filter(df, outcome==1, chairman=={{judge}}), aes(date, outcome), sides="t") +
#         geom_rug(data=filter(df, outcome==0, chairman=={{judge}}), aes(date, outcome), sides="b")
# }

plot_judges(df_top, date)
ggsave("outcome_time_judge.png", height=15, width=25, units="cm")

plot_judges(df_top, counter)
ggsave("outcome_counter_judge.png", height=15, width=25, units="cm")
