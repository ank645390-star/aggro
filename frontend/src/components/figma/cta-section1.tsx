import React from "react";
import Call1 from "./call1";
import styles from "./cta-section1.module.css";
import { useCallbackModal } from "../../context/CallbackContext";
import { useContactInfo } from "../../context/ContactInfoContext";

export type CtaSection1Type = {
  className?: string;
};

/**
 * Section "НЕ ЗНАЙШЛИ ВАШ ПРЕПАРАТ?" — used on /product and /catalog pages.
 *
 * Кнопка «Отримати консультацію» відкриває ту ж саму callback-модалку,
 * що й «Замовити дзвінок» у хедері / footer / каталозі. Номер телефону
 * та значення для click-to-call беруться з ContactInfoContext, тому що
 * адміністратор має змогу змінювати їх в /admin/contact-info.
 */
const CtaSection1: React.FC<CtaSection1Type> = ({ className = "" }) => {
  const { openModal: openCallback } = useCallbackModal();
  const { info } = useContactInfo();

  return (
    <section
      className={[styles.ctaSection, className].join(" ")}
      data-testid="product-cta-section"
    >
      <img loading="lazy" decoding="async"
        className={styles.bg}
        alt=""
        src="/anna-50943-A-modern-agronomist-standing-in-a-lush-green-agricul-cf388352-4200-433f-9f6c-95455d39b194-1@2x.webp"
      />
      {/* subtle scrim so the cream type contrasts on the photo */}
      <div className={styles.scrim} aria-hidden="true" />

      <div className={styles.mainContent}>
        <div className={styles.headline}>
          <h2 className={styles.title} data-testid="product-cta-title">
            Не знайшли ваш препарат?
          </h2>
          <h3 className={styles.subtitle} data-testid="product-cta-subtitle">
            Ми безкоштовно підберемо схему захисту під вашу культуру.
          </h3>
        </div>

        <div className={styles.buttonGroup}>
          <button
            type="button"
            className={styles.ctaButton}
            data-testid="product-cta-button"
            onClick={openCallback}
          >
            <span className={styles.ctaLabel}>Отримати консультацію</span>
            <span className={styles.ctaIcon} aria-hidden="true">
              <Call1 size={24} />
            </span>
          </button>
          <a
            href={`tel:${info.phone_primary_tel}`}
            className={styles.phone}
            data-testid="product-cta-phone"
          >
            {info.phone_primary}
          </a>
        </div>
      </div>
    </section>
  );
};

export default CtaSection1;
