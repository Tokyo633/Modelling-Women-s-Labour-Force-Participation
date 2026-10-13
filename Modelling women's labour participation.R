setwd("C:/Users/grace/OneDrive/Documents/School Stuff/Semester 4/Advanced Regression/Lab 2 assignment")
labour<-read.csv("labor_participation")
# ============================================================
# EDA — Labour Force Participation
# ============================================================

# ---- Correlation matrix ----
round(cor(labour), 3)

library(ggplot2); library(gridExtra); library(dplyr)

p1 <- ggplot(labour, aes(x = educ)) +
  geom_histogram(binwidth = 1, fill = "#4292c6", colour = "white") +
  labs(title = " ", x = "Years of education", y = "Count") +
  theme_minimal() + theme(panel.grid = element_blank(), plot.margin = margin(t=5,r=5,b=2,l=2))

p2 <- ggplot(labour, aes(x = nwifeinc)) +
  geom_histogram(bins = 25, fill = "#4292c6", colour = "white") +
  labs(title = " ", x = "Other household income ($000s)", y = "Count") +
  theme_minimal() + theme(panel.grid = element_blank(), plot.margin = margin(t=5,r=5,b=2,l=2))

p3 <- ggplot(labour, aes(x = factor(kidslt6), fill = factor(inlf))) +
  geom_bar(position = "fill") +
  scale_fill_manual(values = c("0"="#9ecae1","1"="#08306b"),
                    labels = c("Not in labour force","In labour force"), name = NULL) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = " ", x = "Children under 6", y = "Proportion") +
  theme_minimal() + theme(panel.grid = element_blank(), legend.position = "bottom",
                          plot.margin = margin(t=5,r=5,b=2,l=2))
p4_data <- labour %>%
  mutate(educ_band = cut(educ, breaks = c(6,9,12,15,18),
                         labels = c("7-9","10-12","13-15","16-18"))) %>%
  group_by(educ_band) %>%
  summarise(rate = mean(inlf)*100, .groups = "drop")

p4 <- ggplot(p4_data, aes(x = educ_band, y = rate)) +
  geom_col(fill = "#4292c6") +
  geom_text(aes(label = paste0(round(rate,1), "%")), vjust = -0.4, size = 3) +
  labs(title = " ", x = "Years of education", y = "% in labour force") +
  theme_minimal() +
  theme(panel.grid = element_blank(),
        plot.margin = margin(t=5, r=5, b=2, l=2)) +
  ylim(0, max(p4_data$rate) * 1.2)

labour %>% group_by(kidslt6) %>%
  summarise(n = n(), participated = sum(inlf),
            rate = round(100*mean(inlf),1), .groups = "drop") %>% print()

p4_data %>% print()

# ---- all four on one page ----
grid.arrange(p1, p2, p3, p4, nrow = 2, ncol = 2)

# ============================================================
# Probit model — Labour force participation
# ============================================================
probit <- glm(inlf ~ educ + kidslt6 + nwifeinc,
              family = binomial(link = "probit"),
              data = labour)

summary(probit)

# null model, for the null vs residual deviance comparison
probit_null <- glm(inlf ~ 1, family = binomial(link = "probit"), data = labour)
summary(probit_null)

# ------------------------------------------------------------
# 5. WORKED EXAMPLES — the two-step procedure
#    Step 1: compute z.  Step 2: look up Phi(z) with pnorm()
# ------------------------------------------------------------

# woman with 12 yrs education, no young children, $20k other income
z1 <- -0.9452 + 0.1395*12 - 0.7533*0 - 0.0302*20
pnorm(z1)                      

# same woman, but with one child under 6
z2 <- -0.9452 + 0.1395*12 - 0.7533*1 - 0.0302*20
pnorm(z2)                      

# the class's predict() approach
predictions <- predict(probit,
                       newdata = data.frame(educ    = c(12, 12),
                                            kidslt6 = c(0, 1),
                                            nwifeinc = c(20, 20)),
                       type = "response")
predictions
diff(predictions)



# ------------------------------------------------------------
# 7. PROBIT CURVE
#    (note the -1 on the outcome: factor -> numeric 0/1)
# ------------------------------------------------------------
ggplot(labour, aes(x = educ, y = as.numeric(inlf) - 1)) +
  geom_point(alpha = 0.25, colour = "#4292c6") +
  stat_smooth(method = "glm", se = FALSE, colour = "#08306b",
              method.args = list(family = binomial(link = "probit"))) +
  labs(title = " ", x = "Years of education", y = "In labour force") +
  theme_minimal() +
  theme(panel.grid = element_blank(),
        plot.margin = margin(t=5, r=5, b=2, l=2))

#Post Hoc Analysis 
1. Marginal effect at a reference case
#    Reference woman: educ = 12, kidslt6 = 0, nwifeinc = 20

ref <- data.frame(educ = 12, kidslt6 = 0, nwifeinc = 20)

# baseline probability
predict(probit, newdata = ref, type = "response")

# effect of one additional year of education
predict(probit, newdata = data.frame(educ = 13, kidslt6 = 0, nwifeinc = 20),
        type = "response") - predict(probit, newdata = ref, type = "response")

# effect of one additional child under 6
predict(probit, newdata = data.frame(educ = 12, kidslt6 = 1, nwifeinc = 20),
        type = "response") - predict(probit, newdata = ref, type = "response")

# effect of $10,000 more other household income
predict(probit, newdata = data.frame(educ = 12, kidslt6 = 0, nwifeinc = 30),
        type = "response") - predict(probit, newdata = ref, type = "response")
2. How the effect of children varies across education levels
#    (the probit curve is non-linear, so effects differ by starting point)

educ_seq <- c(9, 12, 15, 18)

res_kids <- sapply(educ_seq, function(e) {
  p0 <- predict(probit, newdata = data.frame(educ = e, kidslt6 = 0, nwifeinc = 20), type = "response")
  p1 <- predict(probit, newdata = data.frame(educ = e, kidslt6 = 1, nwifeinc = 20), type = "response")
  c(no_child = p0, one_child = p1, change = p1 - p0)
})
round(t(res_kids), 4)

# ------------------------------------------------------------
# 3. Predicted probability across the education range
# ------------------------------------------------------------
educ_range <- data.frame(educ = 7:18, kidslt6 = 0, nwifeinc = 20)
educ_range$prob <- predict(probit, newdata = educ_range, type = "response")
round(educ_range, 4)
4. Predicted probability across the income range
# ------------------------------------------------------------
inc_range <- data.frame(educ = 12, kidslt6 = 0, nwifeinc = seq(5, 65, 10))
inc_range$prob <- predict(probit, newdata = inc_range, type = "response")
round(inc_range, 4)

