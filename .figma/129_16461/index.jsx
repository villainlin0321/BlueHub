import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.frame8}>
      <div className={styles.background}>
        <div className={styles.instance}>
          <p className={styles.time}>10:41</p>
          <img src="../image/mr79vesw-6p8v69v.svg" className={styles.frame} />
        </div>
        <div className={styles.autoWrapper}>
          <div className={styles.instance2}>
            <img src="../image/mr79vesw-yh39zrx.svg" className={styles.frame2} />
          </div>
          <p className={styles.text}>实名认证</p>
        </div>
      </div>
      <div className={styles.bg2}>
        <div className={styles.bg}>
          <p className={styles.text2}>姓名</p>
          <p className={styles.a19870304}>请输入</p>
        </div>
        <div className={styles.bg}>
          <p className={styles.text2}>身份证号</p>
          <p className={styles.a19870304}>请输入</p>
        </div>
        <div className={styles.group12}>
          <div className={styles.group11}>
            <div className={styles.frame3}>
              <p className={styles.text2}>身份证验证</p>
            </div>
            <p className={styles.text3}>请上传本人的身份证照片</p>
          </div>
          <div className={styles.autoWrapper2}>
            <img src="../image/mr79vesw-reb53yi.png" className={styles.frame4} />
            <img src="../image/mr79vesw-51i4qzr.png" className={styles.frame4} />
          </div>
          <div className={styles.autoWrapper3}>
            <p className={styles.text4}>上传国徽面</p>
            <p className={styles.text4}>上传人像面</p>
          </div>
        </div>
      </div>
      <p className={styles.text5}>
        本平台将采集和保存您的身份证照片，并将身份证照片提供至实名核验服务商，用于对您进行身份核验和资质审核
      </p>
      <div className={styles.frame7}>
        <div className={styles.frame6}>
          <div className={styles.frame5}>
            <p className={styles.text6}>同意并提交</p>
          </div>
        </div>
        <div className={styles.homeIndicator} />
      </div>
    </div>
  );
}

export default Component;
