import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.frame16}>
      <div className={styles.bG1}>
        <div className={styles.frame2}>
          <div className={styles.frame}>
            <p className={styles.text}>中</p>
          </div>
          <p className={styles.en}>En</p>
        </div>
        <p className={styles.text2}>注册/登录</p>
        <div className={styles.autoWrapper}>
          <p className={styles.text3}>手机号</p>
          <p className={styles.text4}>邮箱</p>
        </div>
        <div className={styles.frame3} />
        <div className={styles.frame6}>
          <div className={styles.autoWrapper2}>
            <p className={styles.a86}>+86</p>
            <div className={styles.instance}>
              <img src="../image/moe2gci9-pyq9w4n.png" className={styles.frame4} />
              <div className={styles.slice} />
            </div>
            <p className={styles.text5}>请输入手机号</p>
          </div>
          <div className={styles.frame5} />
        </div>
        <div className={styles.autoWrapper3}>
          <p className={styles.text6}>请输入验证码</p>
          <p className={styles.text7}>获取验证码</p>
        </div>
        <div className={styles.frame7} />
        <div className={styles.frame8}>
          <p className={styles.text8}>登录</p>
        </div>
        <div className={styles.frame10}>
          <div className={styles.frame9}>
            <div className={styles.instance2}>
              <div className={styles.checkboxUnselected} />
              <div className={styles.slice2} />
            </div>
          </div>
          <p className={styles.text11}>
            <span className={styles.text9}>同意</span>
            <span className={styles.text10}>
              《XXXA用户服务协议》《XXXA用户隐私政策》
            </span>
          </p>
        </div>
        <div className={styles.autoWrapper4}>
          <div className={styles.frame11}>
            <img src="../image/moe2gci9-jvhzdog.svg" className={styles.logo} />
          </div>
          <div className={styles.frame13}>
            <img src="../image/moe2gcia-h3qqb4y.png" className={styles.frame12} />
          </div>
          <div className={styles.frame15}>
            <img src="../image/moe2gcia-nwqfbhr.png" className={styles.frame14} />
          </div>
        </div>
        <div className={styles.barsHomeIndicatorIPh}>
          <div className={styles.homeIndicator} />
        </div>
      </div>
      <div className={styles.iPhoneXStatusBarsSta}>
        <div className={styles.timeStyle}>
          <p className={styles.aTime3}>
            <span className={styles.aTime}>9:4</span>
            <span className={styles.aTime2}>1</span>
          </p>
        </div>
        <img
          src="../image/moe2gci9-08dvhei.svg"
          className={styles.cellularConnection}
        />
        <img src="../image/moe2gci9-icb8mf7.svg" className={styles.wifi} />
        <img src="../image/moe2gci9-25sb08n.svg" className={styles.battery} />
      </div>
    </div>
  );
}

export default Component;
