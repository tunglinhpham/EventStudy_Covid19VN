# The effect of the COVID-19 outbreak on stock performance: An analysis in Viet Nam’s stock market.

This is the project analyzing the impact of the first outbreak of the novel coronavirus in Vietnam, starting from March 9<sup>th</sup>, 2020 to April 1<sup>st</sup>, 2021.

## Data & Methodology

### Data

The data used in this project is the return of 95 companies from 3 indices: VN-30 Index (largest 30 companies), VN-Mid Cap Index (70 mid-cap companies), and VN-Small Cap Index (158 small-cap companies).
Those companies' return are then grouped into 8 sectors according to Bloomberg's classification,
which are ***Industrials***, ***Materials***, ***Consumer Discretionary***, ***Real Estate***, ***Financials***, ***Consumer Staples***, ***Energy & Utilities***, and ***Others***.

### Methodology
The method of this project follows the Event Study method. The math intuitions behind the Event Study method could be found in the following paper [Event Studies in Economics and Finance by A. Craig MacKinley](https://www.jstor.org/stable/2729691).
In this project, I defined 2 periods as follows.
The first period (Estimation window, or L<sub>1</sub>, from January 4<sup>th</sup>, 2016 to March 6<sup>th</sup>, 2020) is used to estimate the parameters of the models that (partly) describes how return of each sector fluctuates during L<sub>1</sub>.
The models are then applied in the second period (Event window, or L<sub>2</sub>, from March 9<sup>th</sup>, 2020 to April 1<sup>st</sup>, 2020) to estimate the expected excess return (or return) during L<sub>2</sub>.
The Event window ended at April 1<sup>st</sup>, 2020 as the Vietnam government issued a countrywide 2-week lockdown, effective from April 1<sup>st</sup>, 2020. After the lockdown, Vietnam recorded a 99-day without new COVID-19 case in the community[^1].

[^1]: All the new cases during that 99-day period were from abroad and they were quarantined immediately.

I used 2 models to add more robustness of my analysis.
The first model is the Capital Asset Pricing Model (or CAPM), augmented with the premium of investing in smaller firm (or SMB factor, from [Common risk factors in the returns on stocks and bonds by Eugene A. Fama & Kenneth R. French](https://www.sciencedirect.com/science/article/abs/pii/0304405X93900235)):

![Augmented CAPM](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/Augmented%20CAPM.png)

in which ***ER<sub>it</sub>*** is the excess return (return over risk-free rate) of the sector ***i*** at time ***t***,
***α<sub>i</sub>*** is the intercept,
***β<sub>i</sub>*** is how sensitive the sector ***i***'s excess return is to the excess return of the market,
***R<sub>mt</sub>*** is the return of the market at time ***t*** (the return of the VN-Index),
***R<sub>ft</sub>*** is the return of the market at time ***t*** (annualized rate of 3-month Vietnam government bond),
***γ<sub>i</sub>*** is the sensitivity of sector ***i***'s excess return to the premium of investing in smaller firms,
***SMB<sub>t</sub>*** is the return of the VN-Small Cap Index minus return of the VN-30 Index (small minus big - SMB).

The second model is the Market Model:

![Market Model](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/Market%20Model.png)

in which ***R<sub>it</sub>*** is the return of the sector ***i*** at time ***t***,
***α<sub>i</sub>*** is the intercept,
***β<sub>i</sub>*** is how sensitive the sector ***i***'s return is to the return of the market,
***R<sub>mt</sub>*** is the return of the market at time ***t*** (the return of the VN-Index).

## Results

### The Augmented CAPM

#### Estimated Coefficients and R<sup>2</sup>:

Sector	| Intercept  - α<sub>i</sub> (std. error) |	Sensitivity to Market excess return – β<sub>i</sub> (std. error) |	Sensitivity to SMB factor – γ<sub>i</sub> (std. error) |	R<sup>2</sup>
| :--- | :---: | :---: | :---: | :---: |
**Industrials**	| -0.060*** (0.018)	| 0.947*** (0.023) | 0.540*** (0.031) |	64.78% |
**Materials**	| -0.060** (0.023) | 1.068*** (0.030)	| 0.612*** (0.040) | 58.01% |
**Consumer Discretionary** | 0.000 (0.020) | 1.034*** (0.027) | 0.673*** (0.035) | 62.16% |
**Real Estate** | -0.014 (0.026) | 1.207*** (0.034) | 0.751*** (0.045) | 58.35% |
**Financials** | -0.032 (0.024) | 1.245*** (0.031) | 0.206*** (0.041) | 71.06% |
**Consumer Staples** | -0.043 (0.024) | 0.936*** (0.031) | 0.392*** (0.042) | 52.22% |
**Energy & Utilities** | -0.077 (0.040) | 1.432*** (0.052) | 0.665*** (0.069) | 47.25% |
**Others** | -0.048 (0.052) | 1.178*** (0.069) | 0.696*** (0.092) | 24.30% |

Note: *** - significant at confidence level of 0.1%; ** - significant at confidence level of 1%; * - significant at confidence level of 5%.

#### Actual Excess Return vs. Expected Excess Return

It is found that in this model's result, the ***Financials*** and ***Materials*** sectors were positively affected during the first COVID-19 outbreak in Vietnam,
while the ***Industrials***, ***Consumer Discretionary***, ***Real Estate***, ***Consumer Staples***, and ***Others*** sectors were negatively affected.
The only sector that seemed unaffected by the outbreak is the ***Energy & Utilities*** sector.

The following graphs demonstrate the Actual Excess Return (red line), Expected Excess Return (red dashed line), and their difference (pink ribbon) in the Event window L<sub>2</sub>:

![CAPM - CD](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Consumer_Discretionary.png)

![CAPM - CS](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Consumer_Staples.png)

![CAPM - EU](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Energy_Utilities.png)

![CAPM - F](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Financials.png)

![CAPM - I](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Industrials.png)

![CAPM - M](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Materials.png)

![CAPM - RE](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Real_Estate.png)

![CAPM - Others](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/CAPM_Others.png)

### The Market Model

#### Estimated Coefficients and R<sup>2</sup>:

Sector	| Intercept  - α<sub>i</sub> (std. error) |	Sensitivity to Market return – β<sub>i</sub> (std. error) | R<sup>2</sup>
| :--- | :---: | :---: | :---: |
***Industrials*** | -0.049* (0.020) | 0.683*** (0.020) | 53.74%
***Materials*** | -0.048 (0.026) | 0.769*** (0.026) | 48.03%
***Consumer Discretionary*** | 0.011 (0.024) | 0.704*** (0.024) | 47.83%
***Real Estate*** | -0.004 (0.029) | 0.839*** (0.029) | 46.21%
***Financials*** | -0.018 (0.024) | 1.144*** (0.024) | 70.31%
***Consumer Staples*** | -0.030 (0.025) | 0.744*** (0.025) | 47.85%
***Energy & Utilities*** | -0.066 (0.041) | 1.107*** (0.042) | 42.25%
***Others*** | -0.037 (0.054) | 0.838*** (0.054) | 19.81%

Note: *** - significant at confidence level of 0.1%; ** - significant at confidence level of 1%; * - significant at confidence level of 5%.

#### Actual Return vs. Expected Return

Similar to the Augmented CAPM, the Market Model yielded the same result in the ***Financials*** industry, which was positively affected by the first COVID-19 outbreak (at the confidence level of 95%).
However, the ***Materials*** sector was statiscally unaffected by the outbreak. Meanwhile, other industries suffered a negative effect from the outbreak.

The following graphs demonstrate the Actual Return (red line), Expected Return (red dashed line), and their difference (pink ribbon) in the Event window L<sub>2</sub>:

![MM - CD](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Consumer_Discretionary.png)

![MM - CS](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Consumer_Staples.png)

![MM - EU](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Energy_Utilities.png)

![MM - F](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Financials.png)

![MM - I](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Industrials.png)

![MM - M](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Materials.png)

![MM - RE](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Real_Estate.png)

![MM - Others](https://github.com/tunglinhpham/EventStudy_Covid19VN/blob/main/Other%20Resources/MM_Others.png)

### Conclusion

The two models both showed that: while other sectors were in adverse effect, the ***Financials*** sector got the opposite result.
One possible explanation for this result is how quickly the State Bank of Vietnam (SBV) reacted to the situation, with the issuance of the Circular 01/2020/TT-NHNN.
This Circular instructed the credit institutions to restructure the current loans, waive and reduce interests and fees, and delay the downgrade of debt classification for their customers ([SBV Releases Measures to Address Impact of COVID-19 Pandemic](https://www.moodysanalytics.com/regulatory-news/may-08-20-sbv-releases-measures-to-address-impact-of-covid-19-pandemic)).
First, SBV required financial institutions to provide criteria to identify customers whose income or cash flows are affected by the COVID-19 pandemic.
After that, those customers’ payments are properly reduced and rescheduled, while the interests are reduced, and fees are partly or even fully waived.
This action helped the businesses to maintain a healthy cashflow and reduced financial cost, while individuals could temporarily delay their payments if they lost their job or had their salary reduced due to the pandemic.
Second, and also the most important point that helped the Financials sector to outperform the market is the delay of downgrading debt classification.
Since both businesses and individuals would be in financial distress during the pandemic, their debts are potentially subjected to be late, which would instantly downgrade their debt classification.
This downgrading would make the financial institutions to increase provision for those loans, which would directly decrease the profit of the financial institutions, especially the credit ones such as banks.
The delay of debt downgrading helped the banks to maintain their expected profit while the pandemic was still in place, which is a “paradox” ([The great banking profit paradox of Covid-hit 2020](https://e.vnexpress.net/news/business/industries/the-great-banking-profit-paradox-of-covid-hit-2020-4218487.html)).
